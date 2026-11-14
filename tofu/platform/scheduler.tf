# Nightly stop at 23:00 Brussels time (Platform Design Decisions, 19). The role
# may stop this one instance and nothing else. For a client trial, disable the
# schedule in a pull request for its dates.

data "aws_iam_policy_document" "scheduler_trust" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["scheduler.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [local.account_id]
    }
  }
}

resource "aws_iam_role" "scheduler" {
  name               = "platform-scheduler"
  description        = "EventBridge Scheduler: stop platform-aws-01 at night"
  assume_role_policy = data.aws_iam_policy_document.scheduler_trust.json
}

data "aws_iam_policy_document" "scheduler_stop" {
  statement {
    actions   = ["ec2:StopInstances"]
    resources = [aws_instance.host.arn]
  }
}

resource "aws_iam_role_policy" "scheduler_stop" {
  name   = "stop-host"
  role   = aws_iam_role.scheduler.id
  policy = data.aws_iam_policy_document.scheduler_stop.json
}

resource "aws_scheduler_schedule" "nightly_stop" {
  name                         = "platform-nightly-stop"
  description                  = "Stop platform-aws-01 at 23:00 Brussels time"
  schedule_expression          = "cron(0 23 * * ? *)"
  schedule_expression_timezone = "Europe/Brussels"
  state                        = "ENABLED"

  flexible_time_window {
    mode = "OFF"
  }

  target {
    arn      = "arn:aws:scheduler:::aws-sdk:ec2:stopInstances"
    role_arn = aws_iam_role.scheduler.arn
    input    = jsonencode({ InstanceIds = [aws_instance.host.id] })
  }
}
