module "label_monthly_total" {
  source  = "git@github.com:bendoerr/terraform-null-label?ref=v0.3.0"
  context = var.context
  name    = "budget-monthly-total"
}

resource "aws_budgets_budget" "monthly_total" {
  name         = module.label_monthly_total.id
  budget_type  = "COST"
  limit_amount = var.budget_monthly_limit
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  notification {
    comparison_operator        = "GREATER_THAN"
    notification_type          = "ACTUAL"
    threshold                  = 50
    threshold_type             = "PERCENTAGE"
    subscriber_email_addresses = var.budget_alert_emails
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    notification_type          = "FORECASTED"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    subscriber_email_addresses = var.budget_alert_emails
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    notification_type          = "ACTUAL"
    threshold                  = 90
    threshold_type             = "PERCENTAGE"
    subscriber_email_addresses = var.budget_alert_emails
  }
}

output "aws_budgets_budget_monthly_total_name" {
  value = aws_budgets_budget.monthly_total.name
}

output "aws_budgets_budget_monthly_total_account" {
  value = aws_budgets_budget.monthly_total.account_id
}
