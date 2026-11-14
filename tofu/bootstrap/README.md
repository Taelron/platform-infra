# tofu/bootstrap

The pieces the pipeline needs before it can run, in the account `taelron-platform`:

- the S3 bucket `platform-tofu-state-181841605684` (Frankfurt) for the state of
  every root, versioned, encrypted, public access blocked, locked with
  `use_lockfile` (no DynamoDB);
- the GitHub OIDC provider and two roles GitHub Actions assumes, so no AWS key is
  ever stored in GitHub:
  - `platform-github-plan`: read-only, from pull requests in
    `Taelron/platform-infra`;
  - `platform-github-apply`: from the environment `aws-apply` only, which accepts
    deployments from `main` only and waits for an approval;
- the Red Hat Cloud Access role and policy, created by hand in Phase 1 and
  imported here.

This root is applied **from the RHEL box only**, with an Identity Center session.
The apply role cannot change it.

## First apply

The bucket does not exist before the first apply, so it runs on a local state,
which then moves into the bucket.

```sh
export AWS_PROFILE=platform
aws sso login --use-device-code
printf 'terraform {\n  backend "local" {}\n}\n' > backend_override.tf
tofu init
tofu plan -out=bootstrap.tfplan
tofu apply bootstrap.tfplan
rm backend_override.tf
tofu init -migrate-state
rm terraform.tfstate terraform.tfstate.backup
```

`TF_VAR_redhat_cloud_access_external_id` must be set for every plan; it is read
from `pass` at run time and never written to a file:

```sh
export TF_VAR_redhat_cloud_access_external_id="$(pass show taelron/redhat/cloud-access-external-id | head -n1)"
```

The box is headless: `--use-device-code` prints a URL and a code to open in a
browser on another machine.

## Later changes

```sh
export AWS_PROFILE=platform
tofu init
tofu plan -out=bootstrap.tfplan
tofu apply bootstrap.tfplan
git fetch --tags
../../tools/inventory/publish.sh bootstrap
```

The last command updates the inventory page of Taelron Docs
(`/platform/inventory/`): the pipeline rebuilds it after every apply of
`tofu/platform` and `tofu/docs`, but never applies this root.
