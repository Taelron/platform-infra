# tools/inventory

Builds the page `/platform/inventory/` of Taelron Docs: what OpenTofu has
provisioned in AWS, by project (`Project` tag) and component (`Component`
tag).

| File         | Does                                                |
|--------------|-----------------------------------------------------|
| `filter.jq`  | One root's state to `<root>.json`, allowlist only   |
| `render.sh`  | Every root's JSON to `index.html`                   |
| `publish.sh` | Filter, upload, rebuild the page, invalidate        |

## What the page may hold

For each taggable AWS resource: address, type, name, `Project`, `Component`,
region, and a one-line summary, headed "At last apply" (recorded by OpenTofu,
not a live reading), from these fields only: instance type and state, volume
size and type, certificate status, bucket
versioning, Lambda runtime, CloudFront status, load balancer type. A listener is named after its protocol ("HTTPS listener"). Untaggable
resources and security group rules are counted per root, not listed. Nothing else: no policy document, no user data, no output, no value
OpenTofu marks sensitive. Add a field to the allowlist in `filter.jq` only if
it is never secret.

## Release per root

The roots table names each root's layer and its last released tag at the
apply (`git describe --tags --match '<layer>-v*'`): `tofu/platform` is
`foundation`, `tofu/bootstrap` is `toolchain`, `tofu/docs` is in no layer.
Until a layer has a tag, it reads "not released".

## When it runs

- `tofu/platform` and `tofu/docs`: after every apply, in the `apply` job of
  `.github/workflows/tofu-root.yml`, with the apply role.
- `tofu/bootstrap`: by hand from the RHEL box after its apply (its README).

`publish.sh` writes `platform/inventory/<root>.json`, reads every root's JSON
back, rebuilds `index.html` with the Platform sidebar of a live page, and
invalidates `/platform/inventory/*`. The publish workflow of
`taelron-docs-site` never deletes that prefix.

## Run by hand

From a root's directory, after `tofu init`, with an Identity Center session:

```sh
export AWS_PROFILE=platform
../../tools/inventory/publish.sh <root>
```
