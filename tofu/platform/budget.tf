# $250 a month for the account before tax, alerts by email at 50, 80 and 100%
# of the actual spend (Platform Design Decisions, 19; raised from $200 before
# the M5 resize, TAE-157). Cost Anomaly Detection mails unexpected spend.

locals {
  # Inventory grouping (TAE-156): every taggable resource of this file.
  budget_tags = { Component = "budget" }
}
resource "aws_budgets_budget" "monthly" {
  name         = "platform-monthly"
  budget_type  = "COST"
  limit_amount = "250"
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  # The limit is before tax: the Belgian VAT is deductible.
  cost_types {
    include_tax = false
  }

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

# One monitor on every AWS service of the account.
resource "aws_ce_anomaly_monitor" "services" {
  name              = "platform-services"
  monitor_type      = "DIMENSIONAL"
  monitor_dimension = "SERVICE"

  tags = local.budget_tags
}

# A daily email for each anomaly whose total impact reaches $10. Email
# subscriptions are daily or weekly; immediate alerts need SNS.
resource "aws_ce_anomaly_subscription" "email" {
  name             = "platform-anomalies"
  frequency        = "DAILY"
  monitor_arn_list = [aws_ce_anomaly_monitor.services.arn]

  subscriber {
    type    = "EMAIL"
    address = local.alert_email
  }

  threshold_expression {
    dimension {
      key           = "ANOMALY_TOTAL_IMPACT_ABSOLUTE"
      match_options = ["GREATER_THAN_OR_EQUAL"]
      values        = ["10"]
    }
  }

  tags = local.budget_tags
}
