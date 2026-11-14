# tofu/docs

The hosting of Taelron Docs (`docs.taelron.com`), in the account
`taelron-platform`. Its own state key (`docs/terraform.tfstate`) in the
platform's state bucket. Only the hosting is code: the pages are published to
the bucket outside Git.

| File             | Holds                                          |
|------------------|------------------------------------------------|
| `bucket.tf`      | Private S3 bucket, versioned, eu-central-1     |
| `certificate.tf` | ACM certificate, us-east-1                     |
| `cognito.tf`     | User pool, MFA, three groups, one app client   |
| `edge.tf`        | Lambda@Edge functions, us-east-1               |
| `cloudfront.tf`  | Distribution and origin access control         |
| `outputs.tf`     | Bucket, distribution, the two DNS records      |

The bucket has `prevent_destroy`: it holds the only copy of the pages.

## What the edge does

Every request goes through `check-auth` (viewer request):

- not signed in: redirect to Cognito's sign-in page;
- `/`, `/assets/*`, `/denied/*`: any signed-in reader;
- `/handbook/*`, `/platform/*`, `/fleetdesk/*`: the group `docs-handbook`,
  `docs-platform` or `docs-fleetdesk`;
- a space without its group, or any other path: the page `/denied/`;
- a path ending in `/` serves its `index.html`.

`http-headers` (origin response) adds the security headers and gives every
page under `/denied/` the status 403. `/parseauth`, `/refreshauth` and
`/signout` are handled by their own function.

A reader's groups are read from their ID token: a change of group takes effect
at their next sign-in, or within the hour, when the token is refreshed.

## Applying

Through GitHub Actions only (`.github/workflows/tofu-docs.yml`), as for
`tofu/platform`: plan on the pull request, apply on merge after approval in
the environment `aws-apply`.

Two records go in Microsoft 365, zone `taelron.com`:

1. **During the first apply:** the certificate's validation CNAME. It is
   known only once the apply has created the certificate; read it with
   `aws acm describe-certificate --region us-east-1` and add it while the apply
   waits (45 minutes at most). It is also the output `acm_validation_record`.
2. **After the apply:** the CNAME `docs` to the distribution, output
   `docs_cname`.

## Changing the edge functions

`edge/` holds the functions, taken from
[aws-samples/cloudfront-authorization-at-edge](https://github.com/aws-samples/cloudfront-authorization-at-edge)
(MIT-0, see `edge/README.md`). The bundles in `edge/dist` are committed; the
pipeline rebuilds them and fails if they differ from the source:

```sh
cd tofu/docs/edge
npm ci
npm test
npm run build
```

Commit `dist/` with the source.
