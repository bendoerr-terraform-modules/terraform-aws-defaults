module "label_account_alias" {
  source  = "git@github.com:bendoerr-terraform-modules/terraform-null-label?ref=v0.4.0"
  context = var.context
  name    = var.iam_alias_postfix
}

module "iam_account" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-account"
  version = "5.30.2"

  account_alias = module.label_account_alias.id

  create_account_password_policy = true
  allow_users_to_change_password = true
  hard_expiry                    = false
  max_password_age               = 365
  minimum_password_length        = 32
  password_reuse_prevention      = null
  require_lowercase_characters   = true
  require_numbers                = true
  require_symbols                = true
  require_uppercase_characters   = true
}