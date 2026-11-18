# Protected default branch (Versioning and Releases, pattern 7): organization
# rulesets on the default branch of every Taelron repository, with an empty
# bypass list. The PO approves and squash-merges; no agent approves or merges.
#
# The approval that counts is the PO's: code owner review is required, and the
# CODEOWNERS file of every repository names the PO as owner of every path. A
# workflow token may approve pull requests (actions.tf), but it is no code
# owner, so its approval does not satisfy the rule.
#
# Two rulesets, because GitHub applies an exclusion to a whole ruleset, not to
# one of its rules: taelron-docs-site is excluded from the pull request rule
# only (its pages are published to main directly), and keeps the ban on
# force pushes and deletion.

locals {
  # Excluded from the pull request rule, each with its reason in pattern 7.
  review_excluded_repositories = ["taelron-docs-site"]
}

resource "github_organization_ruleset" "default_branch" {
  name        = "default-branch"
  target      = "branch"
  enforcement = "active"

  conditions {
    ref_name {
      include = ["~DEFAULT_BRANCH"]
      exclude = []
    }
    repository_name {
      include = ["~ALL"]
      exclude = []
    }
  }

  rules {
    deletion         = true
    non_fast_forward = true
  }
}

resource "github_organization_ruleset" "default_branch_review" {
  name        = "default-branch-review"
  target      = "branch"
  enforcement = "active"

  conditions {
    ref_name {
      include = ["~DEFAULT_BRANCH"]
      exclude = []
    }
    repository_name {
      include = ["~ALL"]
      exclude = local.review_excluded_repositories
    }
  }

  rules {
    pull_request {
      required_approving_review_count   = 1
      dismiss_stale_reviews_on_push     = true
      require_last_push_approval        = true
      require_code_owner_review         = true
      required_review_thread_resolution = false
      allowed_merge_methods             = ["squash"]
    }
  }
}
