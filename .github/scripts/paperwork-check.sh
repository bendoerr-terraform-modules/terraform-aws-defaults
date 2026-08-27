#!/usr/bin/env bash
# paperwork-check.sh [repo-root]  -- new-repo checklist tripwire for template descendants.
#
# It SCANS and REPORTS. It does not decide: the caller splits the decision into a separate step so
# that the FAILING STEP'S NAME is the diagnosis. `::error::` is prose in a pane, and two different
# reds render as the same X.
#
#   0  CLEAN           scanned N files, nothing found        (N is always printed)
#   1  FINDINGS        placeholders and/or self-references remain
#   2  NOT MEASURED, in two distinct sentences because they need different fixes:
#        SCAN FAILED      the tool errored (git grep 128 / 129, unreadable root, unwritable output)
#        NOTHING SCANNED  the pathspec matched ZERO files -- a green over an empty set is vacuous
#
# THE FINDINGS FILE IS PART OF THE CONTRACT. It is written on EVERY 0 and EVERY 1 -- empty on 0,
# non-empty on 1 -- so the caller can assert the handoff rather than trust it. A scanner that
# greens without doing its paperwork is the green-green hole.
#
# WHY 2 EXISTS AT ALL (2026-08-27). This gate used to read:
#     todos=$(git grep -n 'TEMPLATE_TODO_' -- ':!.github' || true)
#     if [ -n "$todos" ]; then ...; fail=1; fi
# `git grep` exits 1 on NO MATCH and 128 on a REAL ERROR. `|| true` collapsed both into an empty
# variable, and empty is the PASS branch. Measured in a non-repository directory: the step printed
# `fatal: not a git repository` TWICE, then printed `paperwork ok`, and exited 0. Never silent --
# GREEN, and nobody reads a green job's log.
#
# 🔴 THE DENOMINATOR IS NECESSARY AND NOT SUFFICIENT, and this is the sharpest thing measured all
# morning (Lilith, 2026-08-27, refuting her own control): `git ls-files` reads the INDEX and
# `git grep` reads the FILESYSTEM. They are TWO POPULATIONS. With one tracked file unreadable and
# a needle planted only inside it, the count-only form printed
#     clean over 4 files
# over a set that had three readable members -- a confident verdict with a correct-looking
# denominator. ⇒ WORSE THAN NO DENOMINATOR: a bare "clean" invites "clean over what?"; a wrong
# "clean over 4 files" ANSWERS that question. That is why the stderr arm above, not the count, is
# what closes this. CENSUS UNIT != REMEDIATION UNIT.
# (The obvious structural alternative -- compare `ls-files` against `grep -l ''` -- was built and
# REFUTED before adoption: an empty tracked file is legitimately absent from `grep -l ''`, so a
# bare count-comparison reds a clean tree.)
#
# WHY THE DENOMINATOR EXISTS. `rc=1` does not mean clean. Measured, three worlds, byte-identical
# output and byte-identical rc:  genuine clean n=1 rc=1 · empty checkout n=0 rc=1 · wrong
# working-directory n=0 rc=1.  A scanner that will not print its denominator has not told you it
# found nothing, only that it said nothing. This failure is WORSE than the 128 case: 128 at least
# leaves a `fatal:` in the log; zero-denominator leaves nothing at all.
#
# PATHSPEC DRIFT, both directions, measured -- keep both halves, the one-sided version over-claims:
#   positive pathspec drift ('src/' renamed)  -> NARROWS SILENTLY (rc=1, empty, no stderr) -- the
#                                                dangerous direction.
#   negative pathspec drift (':!.githubb')    -> WIDENS LOUDLY (rc=0; the scan reaches .github and
#                                                matches this very file) -- the harmless one.
# This gate uses the NEGATIVE form, so it is not exposed to the silent route. The denominator arm
# is here for the empty-checkout and wrong-working-directory routes.
#
# WHY NOT `grep -c` FOR THE COUNT. `grep -c .` on empty input prints 0 and EXITS 1. Under
# `set -euo pipefail` the assignment dies and the NOT MEASURED line is never reached -- an
# ANONYMOUS red. Measured both ways: dead under -e, reached under `set -uo pipefail`. The safe
# reading was a property of a shell setting nobody chose, so the count below uses `wc -l` over a
# variable (cannot fail) with `git ls-files`' rc mapped explicitly.
#
# This file lives under .github/, which the ':!.github' pathspec EXCLUDES, so it may safely contain
# the needles it searches for. That exclusion is LOAD-BEARING: remove it and this script matches
# itself and the gate fails forever. CI asserts it.
set -uo pipefail

ROOT="${1:-.}"
# 🔴 THE DEFAULT MUST NOT LIVE INSIDE THE SCANNED TREE. It used to be `./paperwork-findings.txt`,
# and the file embeds BOTH needles verbatim. Measured: run the gate locally in a descendant, fix
# the checklist, `git add -A`, and the gate reds FOREVER -- on its own artifact
# (`paperwork-findings.txt:4`). A guard that cannot go green after the fault is fixed is worse than
# one that never fired. Default now lands in TMPDIR; CI passes `${{ runner.temp }}` explicitly.
OUT="${PAPERWORK_FINDINGS:-${TMPDIR:-/tmp}/paperwork-findings.txt}"
case "$OUT" in /*) ;; *) OUT="$PWD/$OUT" ;; esac   # resolve BEFORE cd, or it lands in $ROOT

cd "$ROOT" 2>/dev/null || { echo "SCAN FAILED - cannot enter '$ROOT'"; exit 2; }

PATHSPEC=':!.github'

# --- denominator first: a verdict without one is not a verdict -------------------------------
rc=0
files=$(git ls-files -- "$PATHSPEC") || rc=$?
if [ "$rc" -ne 0 ]; then
  echo "SCAN FAILED - 'git ls-files -- $PATHSPEC' exited $rc; the paperwork gate did not run"
  exit 2
fi
if [ -z "$files" ]; then n=0; else n=$(printf '%s\n' "$files" | wc -l | tr -d ' '); fi
# 🔴 POPULATION MISMATCH -- the third route, and the stderr arm does NOT cover it.
# `git ls-files` reads the INDEX; `git grep` reads the WORKTREE. A tracked file deleted from the
# worktree is COUNTED in n and silently NOT SEARCHED, and git grep writes nothing to stderr.
# Measured: 2 tracked files, README.md deleted, needle inside it -> `CLEAN - scanned 2 file(s)`,
# rc=0. That is precisely the "confident verdict carrying a correct-looking denominator" this
# header calls worse than no denominator, arriving by a route neither the stderr arm nor the
# count catches. Unreachable from a fresh `actions/checkout`; reachable in the manual
# `[repo-root]` mode and under any sparse or partial checkout.
# rc-MAPPED, not `2>/dev/null` with the status discarded. The first cut of THIS arm -- added an
# hour ago, in the file whose header forswears exactly this -- swallowed stderr and never checked
# the status, so an `ls-files` error collapsed to missing="" and the population arm silently did
# not fire. The oldest class in the newest guard. (kitten, review 5041240974.)
# ⚠️ AND THIS REFUSAL IS DEFENSIVE, NOT EXERCISED -- said out loud rather than left to read as
#    tested. Both `ls-files` calls read the same index, and the census above runs first, so every
#    world I could build that breaks one (measured: a corrupt GIT_INDEX_FILE -> rc=128) is caught
#    by the census and never reaches here. A worktree stat failure does NOT make `--deleted` exit
#    non-zero; it reports the path as deleted, which the arm below already handles. It stays
#    because the alternative is the shape this file exists to abolish, but no arm covers it.
mrc=0
missing=$(git ls-files --deleted -- "$PATHSPEC") || mrc=$?
if [ "$mrc" -ne 0 ]; then
  echo "SCAN FAILED - 'git ls-files --deleted -- $PATHSPEC' exited $mrc; the population could not"
  echo "  be checked, so the denominator cannot be trusted and this is NOT a clean result"
  exit 2
fi
if [ -n "$missing" ]; then
  echo "POPULATION MISMATCH - $(printf '%s\n' "$missing" | wc -l | tr -d ' ') tracked file(s) are"
  echo "  counted by the census but cannot be stat'd in the worktree - deleted, or sitting under a"
  echo "  directory this process cannot traverse. Either way they are NOT searched and the"
  echo "  denominator would be a lie. (git ls-files --deleted stats; it cannot tell absent from"
  echo "  unreadable, and this verdict deliberately claims only what it measured.) Offenders:"
  printf '%s\n' "$missing" | sed 's/^/    /'
  exit 2
fi

if [ "$n" -eq 0 ]; then
  echo "NOTHING SCANNED - pathspec '$PATHSPEC' matched 0 files. This is NOT a clean result: a green"
  echo "  over an empty set is vacuous. Check the checkout, the working-directory and the pathspec."
  exit 2
fi

# 0 = matched (prints hits) | 1 = clean | 2 = the scan itself failed
#
# 🔴 THE EXIT CODE IS NOT SUFFICIENT, measured 2026-08-27 and this is the third false-clean route:
#   unreadable tracked FILE      -> `error: failed to stat 'a.md': Permission denied` on stderr,
#                                   and git grep exits **1** -- which every rc map on earth reads
#                                   as "searched, found nothing".
#   unreadable tracked SUBDIR    -> same error on stderr, and it exits **0**, having silently
#                                   omitted the whole subtree while reporting other matches.
# ⇒ git grep's exit code does not reflect PER-PATH read failures at all. The only signal is stderr.
# Neither the rc map nor the denominator catches this: n counts the unreadable file just fine.
# So stderr is part of the verdict, and ANY non-empty stderr refuses -- including `warning:`.
# (An earlier revision of this comment said warnings were passed through, and it survived one
# commit past the code that stopped doing so: prose defending a behaviour the code no longer had,
# in the file whose whole subject is that class. Corrected here rather than left to be read.)
scan() {
  local needle="$1" out src err
  # >&2 is load-bearing: scan() is only ever called as `x=$(scan ...)`, so a bare echo here is
  # captured into the variable and discarded on the `*) exit 2` path -- an ANONYMOUS rc=2, which
  # is the one thing this file's header promises never to emit. Every other refusal in scan()
  # already used >&2; this one did not, and no arm covers it.
  err=$(mktemp) || { echo "SCAN FAILED - cannot create a temp file for stderr" >&2; return 2; }
  out=$(git grep -n "$needle" -- "$PATHSPEC" 2>"$err"); src=$?
  # ANY stderr refuses. NOT an allowlist of known message prefixes: git's wording is
  # version- and locale-dependent, and an enumeration that stops when it looks sufficient is the
  # whole failure class this file exists for. A scanner that said something unexpected has not
  # demonstrated it read everything.
  # FALSE-ALARM COST MEASURED before adopting this, on real subjects rather than reasoned about:
  # 6 invocations over 4 healthy repos (2 repos x 2 needles + 2 repos x 1), stderr 0 bytes every
  # time. State the count exactly: "4 repos x 2 needles" would be 8, and I ran 6.
  # ⚠️ SCOPE: 4 of the 9 fleet repos. The other 5 answer for themselves when each one's selftest
  # first runs -- that is what the per-repo control is for.
  # 📌 PRE-DECIDED, so a first-wave red is not answered in a hurry: if some repo legitimately emits
  # a benign `warning:`, the weakening is an EXPLICIT `^warning:` allowlist, not a revert of the
  # arm. Deciding that now, while nothing is red, is the point of writing it down.
  # 🔴 AND IF THAT WEAKENING EVER SHIPS IT MUST CARRY `LC_ALL=C`. git's `fatal: `/`error: `/
  # `warning: ` prefixes are gettext-wrapped (`usage.c` v2.43.0 :62/:82/:89), so a PREFIX match is
  # locale-dependent and would silently stop matching on a runner that has git's .mo catalogues.
  # The current arm is immune because it matches NO text at all -- it refuses on stderr being
  # non-empty. That immunity is a property of the polarity, and it is exactly what the allowlist
  # would give away. (kitten checked usage.c and refuted his own "prefixes are unlocalized"
  # claim; Lilith found the box has zero .mo files, so the question is moot HERE and unmeasured on
  # a hosted runner.)
  if [ -s "$err" ]; then
    echo "SCAN FAILED - 'git grep $needle' wrote to stderr, so it did not cleanly search the whole" >&2
    echo "  tree (rc=$src is NOT a reliable signal here: git grep's rc is computed over the files it" >&2
    echo "  SUCCESSFULLY READ, so unreadable paths drop out of the population silently and rc" >&2
    echo "  reports on the shrunken set). A path the scanner could not read is not a path it cleared:" >&2
    sed 's/^/    /' "$err" >&2
    rm -f "$err"; return 2
  fi
  rm -f "$err"
  case "$src" in
    0) printf '%s\n' "$out"; return 0 ;;
    1) return 1 ;;
    # ⚠️ DEFENCE IN DEPTH, AND UNEXERCISED -- said out loud rather than left to read as tested.
    #    Every git grep failure I could construct (128 bad pathspec magic / invalid regex / not a
    #    repo, 129 unknown flag) either dies earlier at the `git ls-files` map above or prints
    #    `fatal:`/`error:` and is caught by the stderr arm first. I could not build a world that
    #    reaches HERE. It stays because the day git changes that, this is the difference between a
    #    refusal and a false clean -- but no arm of the selftest covers it, and an arm that has
    #    never run is a decoration until it does.
    *) echo "SCAN FAILED - 'git grep $needle' exited $src over $n file(s); NOT a clean result" >&2
       return 2 ;;
  esac
}

findings=""
add() { findings="${findings}${1}
"; }

todos=$(scan 'TEMPLATE_TODO_'); rc=$?
case "$rc" in
  0) add "unfilled template placeholders remain - complete the new-repo checklist at the top of terraform-module-repo-template's README"
     add "$todos" ;;
  1) ;;
  *) exit 2 ;;
esac

# Substring 'repo-template' is INTENTIONALLY loose: it catches the full repo name (README URLs,
# test/go.mod, test/.golangci.yml) AND ctx.tf's shorter role string ("terraform-aws-repo-template");
# the full name would miss the latter. Scope is a DENYLIST like its sibling above -- an allowlist of
# expected files needed hand-extending twice in one morning; the name goes wherever it likes. A
# child legitimately named *repo-template* would trip this forever -- change the needle if that day
# ever comes.
selfrefs=$(scan 'repo-template'); rc=$?
case "$rc" in
  0) add "template self-references remain (badges/links/example role still point at the template) - see the new-repo checklist at the top of terraform-module-repo-template's README"
     add "$selfrefs" ;;
  1) ;;
  *) exit 2 ;;
esac

# The findings file is written on BOTH 0 and 1 -- its emptiness is the verdict, and the caller
# asserts that invariant rather than trusting it.
printf '%s' "$findings" > "$OUT" 2>/dev/null \
  || { echo "SCAN FAILED - cannot write findings to '$OUT'"; exit 2; }

if [ -s "$OUT" ]; then
  echo "FINDINGS - scanned $n file(s); details in $OUT"
  exit 1
fi
echo "CLEAN - scanned $n file(s); no template placeholders and no template self-references"
exit 0
