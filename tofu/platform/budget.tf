# $200 a month for the account, alerts by email at 50, 80 and 100% of the
# actual spend (Platform Design Decisions, 19).

locals {
  # Inventory grouping (TAE-156): every taggable resource of this file.
  budget_tags = { Component = "budget" }
}
resource "aws_budgets_budget" "monthly" {
  name         = "platform-monthly"
  budget_type  = "COST"
  limit_amount = "200"
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  dynamic "notification" {
    for_each = [50, 80, 100]

    content {
      comparison_operator        = "GREATER_THAN"
      threshold                  = notification.value
      threshold_type             = "PERCENTAGE"
      notification_type          = "ACTUAL"
      subscriber_email_addresses = [local.alert_email]
    }
  }

  tags = local.budget_tags
}
