# tofu/github

The GitHub settings the platform relies on, in the organisation `Taelron`:

- the repositories `platform-infra` and `platform-gitops`: public, secret
  scanning and push protection on, `prevent_destroy`;
- two organisation rulesets on the default branch of every Taelron
  repository, bypass list empty (Versioning and Releases, pattern 10):
  - `default-branch`: no force push, no deletion, on every repository;
  - `default-branch-review`: pull request with 1 approval, stale approvals
    dismissed, the last push approved by someone other than its author, code
    owner review (each repository's `CODEOWNERS` names the PO), squash only; every repository except `taelron-docs-site`, where pages are
    published to `main` directly;
- squash merge only on both, the pull request title as the commit;
- the environment `aws-apply` on `platform-infra`: deployments from `main` only,
  approved by Gaetan, admins cannot bypass it. The apply role in AWS trusts only
  this environment;
- Actions in `platform-infra`: read-only token by default, allowed to open pull
  requests (release-please).

Applied **from the RHEL box only**, never by GitHub Actions: the pipeline would
otherwise hold a token able to remove its own approval gate.

## Not managed here

The provider has no resource for these; set by hand, check after any change:

- Actions, fork pull request workflows: approval required.
- Organisation Taelron, Actions, Workflow permissions: "Allow GitHub Actions
  to create and approve pull requests" on (set by Gaetan, 14 November 2026).
  Without it, the repository setting in `actions.tf` is refused (HTTP 409) and
  release-please cannot open its release pull requests.
- OIDC subject claims: immutable (`repo:Taelron@279244988/platform-infra@1456341560`).
  The roles in `tofu/bootstrap` trust that subject.

## Apply

Signs in as the GitHub App `taelron-platform-admin` (Taelron organisation,
installed on the two repositories only; Organization administration,
Administration, Environments and Secret scanning alerts in write, Metadata in
read). Organization administration covers the organisation rulesets. Its
private key is in `pass`.

```sh
export AWS_PROFILE=platform
aws sso login --use-device-code
export TF_VAR_github_app_private_key="$(pass show taelron/github/platform-admin-key)"
tofu init
tofu plan -out=github.tfplan
tofu apply github.tfplan
```
