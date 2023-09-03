module "aws_defaults" {
  source               = "../.."
  context              = module.context.shared
  budget_monthly_limit = var.budget_monthly_limit
  budget_alert_emails  = var.budget_alert_emails
  iam_alias_postfix    = var.iam_alias_postfix
  network              = var.network
}

output "aws_budgets_budget_monthly_total_name" {
  value = module.aws_defaults.aws_budgets_budget_monthly_total_name
}

output "aws_budgets_budget_monthly_total_account" {
  value = module.aws_defaults.aws_budgets_budget_monthly_total_account
}
