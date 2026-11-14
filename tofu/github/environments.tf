# The gate in front of `tofu apply` in GitHub Actions: deployments from main
# only, each one approved by Gaetan. The apply role trusts only tokens issued
# for this environment (tofu/bootstrap/github.tf).
#
# Created as "production" with the API in Phase 2; imported here and renamed,
# which GitHub does by replacing it.

import {
  to = github_repository_environment.aws_apply
  id = "platform-infra:production"
}

resource "github_repository_environment" "aws_apply" {
  repository          = github_repository.platform["platform-infra"].name
  environment         = "aws-apply"
  prevent_self_review = false
  can_admins_bypass   = false

  reviewers {
    users = [local.approver_user_id]
  }

  deployment_branch_policy {
    protected_branches     = false
    custom_branch_policies = true
  }
}

resource "github_repository_environment_deployment_policy" "aws_apply_main" {
  repository     = github_repository.platform["platform-infra"].name
  environment    = github_repository_environment.aws_apply.environment
  branch_pattern = "main"
}
