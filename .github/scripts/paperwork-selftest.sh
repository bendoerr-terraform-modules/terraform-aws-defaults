#!/usr/bin/env bash
# paperwork-selftest.sh -- exercise paperwork-check.sh against constructed fixtures.
#
# WHY THIS EXISTS (2026-08-27). The `paperwork` job carries
#     if: github.repository != '.../terraform-module-repo-template'
# so THE CANONICAL COPY OF THE GATE HAS NEVER EXECUTED IN THE REPO THAT OWNS IT. It is authored in
# the template, skipped there, and only ever runs in descendants -- a regression introduced in the
# parent is invisible at the parent, and a skipped job reports as `skipped`, which every
# green-check reading in this org correctly treats as non-failing.
#
# The `if:` is not wrong: the template legitimately self-references everywhere, so the selfrefs arm
# would fail forever there. The defect is that nothing replaced the coverage. This does. It runs in
# EVERY repo, template included, because a fixture is not the repo it runs in.
#
# It is also the PER-REPO FORCED CONTROL for the propagation waves: nine copies are nine claims
# until each one's control has fired in its own CI.
#
# FIXTURES ARE SEALED (git add + commit) ON PURPOSE. `git ls-files` counts TRACKED files and
# `git grep` searches TRACKED content, so a fixture that is merely written is INVISIBLE -- measured
# n=0, which made three arms report NOTHING SCANNED instead of their expected verdicts. The
# selftest failed on its own fixtures. The fixture builder decides which worlds can exist, and
# nobody tests the builder.
set -uo pipefail

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
CHECK="$HERE/paperwork-check.sh"
[ -x "$CHECK" ] || { echo "NOT MEASURED - $CHECK missing or not executable"; exit 1; }

TMP=$(mktemp -d) || { echo "NOT MEASURED - cannot create a fixture directory"; exit 1; }
# chmod back before removing: two arms deliberately create unreadable paths.
trap 'chmod -R u+rwX "$TMP" 2>/dev/null; rm -rf "$TMP"' EXIT
FAILED=0; RAN=0

mkrepo() { mkdir -p "$1"; git -C "$1" init -q .
           git -C "$1" config user.email selftest@example.invalid
           git -C "$1" config user.name  selftest; }
# seal() must fail LOUDLY. Swallowing (e.g. a gpgsign failure in a fixture repo) would surface
# two steps later as a NOTHING SCANNED verdict, a long way from its cause.
seal() {
  git -C "$1" add -A || { echo "NOT MEASURED - could not stage fixture in $1"; exit 1; }
  git -C "$1" -c commit.gpgsign=false commit -qm fixture >/dev/null \
    || { echo "NOT MEASURED - could not commit fixture in $1"; exit 1; }
}
# A fixture that did not reach its intended state proves nothing. chmod is a no-op for root, so
# under a root runner arms 8 and 9 would pass while testing NOTHING. Assert the world was built.
# (The fixture builder decides which worlds can exist, and nobody tests the builder.)
require_unreadable() {
  if [ -r "$1" ]; then
    echo "NOT MEASURED - '$1' is still readable after chmod 000 (running as root?); the fixture"
    echo "  for the unreadable-path arms was NOT built, so those arms would prove nothing."
    exit 1
  fi
}

# <label> <dir> <want-rc> <want-verdict-substring> [<want-findings: empty|nonempty|any>]
# ⚠️ THE SUBSTRING MUST DISCRIMINATE WHICH REFUSAL FIRED, not merely that one did. Four arms once
# asserted only "SCAN FAILED" and would each have passed on any of the others' causes -- including
# the never-exercised `*)` branch. A shared verdict substring makes N arms into one arm run N
# times. Needles below are the distinguishing clause of each cause.
arm() {
  local label="$1" dir="$2" want="$3" needle="$4" wantf="${5:-any}" out rc f
  RAN=$((RAN+1))
  f="$TMP/findings.$RAN.txt"; rm -f "$f"
  out=$(PAPERWORK_FINDINGS="$f" "$CHECK" "$dir" 2>&1); rc=$?
  if [ "$rc" -ne "$want" ]; then
    echo "ARM FAILED  $label: rc=$rc want=$want"; printf '%s\n' "$out" | sed 's/^/      /'
    FAILED=1; return
  fi
  if ! printf '%s\n' "$out" | grep -q -- "$needle"; then
    echo "ARM FAILED  $label: rc correct but verdict text lacks '$needle'"
    printf '%s\n' "$out" | sed 's/^/      /'; FAILED=1; return
  fi
  case "$wantf" in
    empty)    [ -f "$f" ] && [ ! -s "$f" ] || { echo "ARM FAILED  $label: findings file must exist and be EMPTY"; FAILED=1; return; } ;;
    nonempty) [ -s "$f" ] || { echo "ARM FAILED  $label: findings file must exist and be NON-empty"; FAILED=1; return; } ;;
  esac
  echo "arm ok      $label: rc=$rc, says '$needle', findings=$wantf"
}

# 1. clean repo -> 0, denominator printed, findings file present and EMPTY
mkrepo "$TMP/clean";   printf 'nothing to see here\n' > "$TMP/clean/README.md"; seal "$TMP/clean"
arm "clean repo"              "$TMP/clean"     0 "CLEAN - scanned 1 file"  empty

# 2. placeholder left behind -> 1, findings NON-empty
mkrepo "$TMP/todo";    printf 'name: TEMPLATE_TODO_module_name\n' > "$TMP/todo/README.md"; seal "$TMP/todo"
arm "placeholder remains"     "$TMP/todo"      1 "FINDINGS"                nonempty

# 3. template self-reference left behind -> 1
mkrepo "$TMP/selfref"; printf 'see terraform-module-repo-template for details\n' > "$TMP/selfref/README.md"; seal "$TMP/selfref"
arm "self-reference remains"  "$TMP/selfref"   1 "FINDINGS"                nonempty

# 4. the scan cannot run -> 2. Before 2026-08-27 this returned 0 and printed "paperwork ok".
mkdir -p "$TMP/notrepo"; printf 'TEMPLATE_TODO_x\n' > "$TMP/notrepo/README.md"
arm "not a git repository"    "$TMP/notrepo"   2 "git ls-files"

# 5. no such root -> 2, a second independent route into the refusal
arm "no such directory"       "$TMP/nope"      2 "cannot enter"

# 6. THE DENOMINATOR ARM: an empty checkout scans zero files. `git grep` returns rc=1 here --
#    byte-identical to a genuine clean -- so nothing but the denominator separates them.
#    Deliberately NOT sealed: zero tracked files IS the arm.
mkrepo "$TMP/emptyrepo"
arm "empty checkout, 0 files" "$TMP/emptyrepo" 2 "NOTHING SCANNED"

# 7. tracked files exist but ALL are excluded by the pathspec -> still zero scanned
mkrepo "$TMP/onlygithub"; mkdir -p "$TMP/onlygithub/.github"
printf 'x\n' > "$TMP/onlygithub/.github/w.yml"; seal "$TMP/onlygithub"
arm "everything excluded"     "$TMP/onlygithub" 2 "NOTHING SCANNED"

# 8. AN UNREADABLE TRACKED FILE. `git grep` prints `error: failed to stat` to stderr and exits
#    **1** -- which an rc map reads as CLEAN, and the denominator counts the file as scanned.
#    Found 2026-08-27 by SABOTAGING arm coverage and watching the selftest stay green: arms 4-6
#    die before scan() is ever called, so scan()'s error arm had never once executed. An arm that
#    has never run is a decoration.
mkrepo "$TMP/unreadable"; printf 'TEMPLATE_TODO_x\n' > "$TMP/unreadable/README.md"
printf 'plain\n' > "$TMP/unreadable/other.md"; seal "$TMP/unreadable"
chmod 000 "$TMP/unreadable/README.md"
require_unreadable "$TMP/unreadable/README.md"
arm "unreadable tracked file"  "$TMP/unreadable" 2 "wrote to stderr"
chmod 644 "$TMP/unreadable/README.md" 2>/dev/null

# 9. AN UNREADABLE TRACKED SUBDIRECTORY. git grep exits **0** having silently omitted the subtree.
#    ⚠️ It refuses at the POPULATION arm, not the stderr arm, and that is measured rather than
#    assumed: `chmod 000` on a DIRECTORY blocks stat of its children, so `ls-files --deleted`
#    flags them first. A chmod'd FILE (arm 8) stats fine and reaches the stderr arm instead.
#    Two unreadable worlds, two different refusals, and only running them shows which.
mkrepo "$TMP/unreadsub"; mkdir -p "$TMP/unreadsub/sub"
printf 'plain\n' > "$TMP/unreadsub/top.md"
printf 'TEMPLATE_TODO_hidden\n' > "$TMP/unreadsub/sub/deep.md"; seal "$TMP/unreadsub"
chmod 000 "$TMP/unreadsub/sub"
require_unreadable "$TMP/unreadsub/sub/deep.md"
arm "unreadable tracked subdir" "$TMP/unreadsub" 2 "POPULATION MISMATCH"
chmod 755 "$TMP/unreadsub/sub" 2>/dev/null

# 10. POPULATION MISMATCH: tracked file deleted from the worktree. Counted by the census, never
#     searched by git grep, and NO stderr -- so neither the count nor the stderr arm sees it.
mkrepo "$TMP/deleted"; printf 'TEMPLATE_TODO_x\n' > "$TMP/deleted/README.md"
printf 'plain\n' > "$TMP/deleted/other.md"; seal "$TMP/deleted"
rm -f "$TMP/deleted/README.md"
arm "tracked file deleted"    "$TMP/deleted"   2 "POPULATION MISMATCH"

FLOOR=10
if [ "$RAN" -ne "$FLOOR" ]; then
  echo "SELFTEST FAILED - only $RAN of $FLOOR arms ran; a stage went quiet"; exit 1
fi
if [ "$FAILED" -ne 0 ]; then
  echo "SELFTEST FAILED - the paperwork gate does not honour its exit contract"; exit 1
fi
echo "SELFTEST PASS - $RAN arms; causes discriminated: CLEAN / FINDINGS / cannot-enter /"
echo "  stderr-written / NOTHING SCANNED / POPULATION MISMATCH"
exit 0
