# tofu/docs

The hosting of Taelron Docs (`docs.taelron.com`), in the account
`taelron-platform`. Its own state key (`docs/terraform.tfstate`) in the
platform's state bucket. Only the hosting is code: the pages are published to
the bucket outside Git.

| File             | Holds                                          |
|------------------|------------------------------------------------|
| `bucket.tf`      | Private S3 bucket, versioned, eu-central-1     |
| `certificate.tf` | ACM certificate, us-east-1                     |
| `cognito.tf`     | User pool, Identity Center provider, client    |
| `edge.tf`        | Lambda@Edge functions, us-east-1               |
| `cloudfront.tf`  | Distribution and origin access control         |
| `publish.tf`     | Role `docs-publish` for the publish workflow   |
| `outputs.tf`     | Bucket, distribution, the two DNS records      |

The bucket has `prevent_destroy`: it holds the only copy of the pages.

## What the edge does

Every request goes through `check-auth` (viewer request):

- not signed in: redirect through Cognito straight to the AWS login (IAM
  Identity Center);
- signed in through Identity Center: every page;
- signed in without it: the page `/denied/` (and `/assets/*`, which it uses);
- a path ending in `/` serves its `index.html`.

`http-headers` (origin response) adds the security headers and gives every
page under `/denied/` the status 403. `/parseauth`, `/refreshauth` and
`/signout` are handled by their own function.

A reader's groups are read from their ID token: a change of group takes effect
at their next sign-in, or within the hour, when the token is refreshed.

## Sign-in

Readers sign in with their AWS login. IAM Identity Center (management
account `310666888351`, eu-central-1) is the pool's only identity provider,
over SAML. Who is assigned to the Identity Center application "Taelron Docs"
(group `docs-readers`) reads the docs; Identity Center applies its own MFA.

AWS creates a customer managed SAML 2.0 application in the console only
(IAM Identity Center, Applications, Add application, "I have an application I
want to set up", SAML 2.0), so it is not in this code. Its values:

| Setting                   | Value                                          |
|---------------------------|------------------------------------------------|
| Display name              | `Taelron Docs`                                 |
| Application ACS URL       | `https://taelron-docs.auth.eu-central-1.amazoncognito.com/saml2/idpresponse` |
| Application SAML audience | `urn:amazon:cognito:sp:eu-central-1_RNuLMrGb6` |
| Attribute `Subject`       | `${user:email}`, emailAddress                  |
| Attribute `email`         | `${user:email}`, unspecified                   |
| Assigned                  | group `docs-readers`                           |

Its SAML metadata URL is `identity_center_metadata_url` in `cognito.tf`.

Signing out of the site ends the site's session only: the next visit signs in
again silently while the AWS login session lasts.

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
