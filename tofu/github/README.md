# tofu/github

The GitHub settings the platform relies on, in the organisation `Taelron`:

- the repositories `platform-infra` and `platform-gitops`: public, secret
  scanning and push protection on, `prevent_destroy`;
- the ruleset `main` on each: pull request required, no force push, no
  deletion;
- the environment `aws-apply` on `platform-infra`: deployments from `main` only,
  approved by Gaetan, admins cannot bypass it. The apply role in AWS trusts only
  this environment.

Applied **from the RHEL box only**, never by GitHub Actions: the pipeline would
otherwise hold a token able to remove its own approval gate.

## Not managed here

The provider has no resource for these; set by hand, check after any change:

- Actions, fork pull request workflows: approval required.
- OIDC subject claims: immutable (`repo:Taelron@279244988/platform-infra@1456341560`).
  The roles in `tofu/bootstrap` trust that subject.

## Apply

Signs in as the GitHub App `taelron-platform-admin` (Taelron organisation,
installed on the two repositories only; Administration, Environments and Secret
scanning alerts in write, Metadata in read). Its private key is in `pass`.

```sh
export AWS_PROFILE=platform
aws sso login --use-device-code
export TF_VAR_github_app_private_key="$(pass show taelron/github/platform-admin-key)"
tofu init
tofu plan -out=github.tfplan
tofu apply github.tfplan
```
