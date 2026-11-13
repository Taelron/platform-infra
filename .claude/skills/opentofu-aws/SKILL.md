---
name: opentofu-aws
description: Taelron Platform rules for OpenTofu on AWS in platform-infra/tofu — bootstrap and platform roots, pinned versions, S3 state with use_lockfile, OIDC roles for GitHub Actions with no keys, platform- names and tags, the plan-on-PR apply-on-approval pipeline, prevent_destroy on data, and manual DNS steps as outputs. Use whenever writing, planning or reviewing OpenTofu for the platform.
---

# OpenTofu on AWS

> Generated from the Taelron baseline **OpenTofu on AWS** (https://linear.app/taelron/document/opentofu-on-aws-a5456732f600), version of 2026-11-13.
> Do not edit by hand: regenerate from the baseline. If this skill and the baseline disagree, the baseline wins.

## Layout

```
tofu/
  bootstrap/   state bucket + GitHub OIDC roles; applied once from the RHEL box,
               then its state moves into the bucket it created
  platform/    everything else, one file per concern:
               network.tf alb.tf instance.tf volumes.tf scheduler.tf
               cognito.tf backups.tf budget.tf outputs.tf versions.tf
```

## Versions and state

- OpenTofu version pinned in the repository; AWS provider pinned to an exact minor version; lock file committed.
- State: S3 in Frankfurt, versioned, encrypted, public access blocked, `use_lockfile = true`, no DynamoDB.

## No keys

- GitHub Actions uses OIDC with two roles: **read-only** for `tofu plan` on pull requests; **apply** assumable only from `main`, behind a protected environment that waits for Gaetan's approval.
- From the RHEL box: Identity Center sessions only (profile `platform`). Never create an access key.

## Names and tags

- Names: `platform-<what>` (`platform-aws-01`, `platform-alb`).
- Tags on every resource: `Project=taelron-platform`, `ManagedBy=opentofu`, `Repository=platform-infra`.
- Region `eu-central-1`; a `us-east-1` provider alias only for the Cognito certificate.

## Pipeline

- Pull request: `tofu fmt -check`, `tofu validate`, `tofu plan` posted as a comment.
- Merge: `tofu apply` of that plan, after approval.

## Data and outputs

- `prevent_destroy` on the eight volumes, the state bucket and the backup buckets. Removing one is a pull request that drops the guard on purpose, said in its title.
- Every record Gaetan enters in Microsoft 365 (certificate validations, CNAMEs) is a named output. Outputs holding a secret are `sensitive`.
