# Edge functions of Taelron Docs

Taken from
[aws-samples/cloudfront-authorization-at-edge](https://github.com/aws-samples/cloudfront-authorization-at-edge),
commit `580a78a032d4fcb43859e0aedc176f8bb38d1349`, licence MIT-0 (`LICENSE`).
Kept: `check-auth`, `parse-auth`, `refresh-auth`, `sign-out`, `http-headers`
and `shared`. Not kept: the CloudFormation template and its custom resources;
OpenTofu (`../edge.tf`) writes each function's `configuration.json` instead.

Changes from upstream, each marked `Taelron Docs` in the code:

- `check-auth`: only the Cognito group `docs-reader` opens the pages
  (`src/check-auth/spaces.ts`, tested in `spaces.test.ts`); without it, a
  page serves `/denied/index.html`; a path ending in `/` serves its
  `index.html`.
- `http-headers`: every page under `/denied/` answers 403.
- `shared`: the JWKS is optional in the configuration and is fetched from
  Cognito on first use.
- `parse-auth`: token request headers typed for current `@types/node`.
- `parse-auth`, `refresh-auth`: the nonce signature is compared in constant
  time, and the error page no longer shows the expected signature (upstream
  printed it, which handed out a valid signature for any nonce).
- Build: one webpack configuration, bundles in `dist/<function>.js`;
  dependencies pinned to exact versions.
