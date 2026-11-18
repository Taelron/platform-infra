# GitHub Actions in platform-infra: the workflow token is read-only by default
# (each workflow asks for what it needs), and Actions may open pull requests,
# which release-please needs for its release pull requests. GitHub grants the
# right to approve pull requests with the same setting, and an approval by a
# workflow counts for the organization rulesets (rulesets.tf): open point on
# TAE-165.

import {
  to = github_workflow_repository_permissions.platform_infra
  id = "platform-infra"
}

resource "github_workflow_repository_permissions" "platform_infra" {
  repository                       = github_repository.platform["platform-infra"].name
  default_workflow_permissions     = "read"
  can_approve_pull_request_reviews = true
}
