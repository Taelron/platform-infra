# Ruleset "main" on each repository: pull request required, no force push, no
# deletion. Created by hand in Phase 2 and imported.

locals {
  ruleset_ids = {
    platform-infra  = 27186761
    platform-gitops = 27186815
  }
}

import {
  for_each = local.ruleset_ids
  to       = github_repository_ruleset.main[each.key]
  id       = "${each.key}:${each.value}"
}

resource "github_repository_ruleset" "main" {
  for_each = local.repositories

  name        = "main"
  repository  = github_repository.platform[each.key].name
  target      = "branch"
  enforcement = "active"

  conditions {
    ref_name {
      include = ["~DEFAULT_BRANCH"]
      exclude = []
    }
  }

  rules {
    deletion         = true
    non_fast_forward = true

    pull_request {
      required_approving_review_count   = 0
      dismiss_stale_reviews_on_push     = false
      require_code_owner_review         = false
      require_last_push_approval        = false
      required_review_thread_resolution = false
      allowed_merge_methods             = ["merge", "squash", "rebase"]
    }
  }
}
