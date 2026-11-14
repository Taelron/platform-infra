# tofu/platform

Everything in the account `taelron-platform` except the bootstrap, one file per
concern (Platform Runbook, Phase 3). Applied only by GitHub Actions:

- **Pull request:** `tofu fmt -check`, `tofu validate`, `tofu plan` with the
  read-only role `platform-github-plan`; the plan is posted as a comment with
  its hash.
- **Merge to `main`:** the job `apply` waits for approval in the environment
  `aws-apply`, plans again with `platform-github-apply`, and applies only if
  the plan's hash matches the one posted on the merged pull request. If `main`
  moved or AWS drifted in between, it stops: open a new pull request.

The plan role reads an allowlist (`tofu/bootstrap/github.tf`, `plan_read`). A
pull request that brings a new AWS service adds its read actions there, applied
from the RHEL box first.
