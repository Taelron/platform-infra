# Changelog

## 1.0.0 (2026-11-14)


### Features

* **ci:** inventory page of Taelron Docs after every apply ([87791ba](https://github.com/Taelron/platform-infra/commit/87791bad0471a104bf48e201f92c42c6999c3e1f))
* **ci:** plan on pull request, apply on merge after approval ([2b539bd](https://github.com/Taelron/platform-infra/commit/2b539bd0512c464694b01201a0ff7c7b4d40d424))
* **docs:** inventory names each layer's release at the apply (Part of TAE-137) ([#24](https://github.com/Taelron/platform-infra/issues/24)) ([047f51a](https://github.com/Taelron/platform-infra/commit/047f51a78c9c9c9ebbd897ece21bfc9897b3b49b))
* **docs:** sign in with the AWS login through IAM Identity Center ([edfe361](https://github.com/Taelron/platform-infra/commit/edfe3616a5d034215eff6a771b810c405c2eff1d))
* **inventory:** column "At last apply", sidebar order, republish on change ([fd73cd0](https://github.com/Taelron/platform-infra/commit/fd73cd050715bd88d6707972947fcbe541e67291))
* **scripts:** platform-start and platform-stop ([79576b3](https://github.com/Taelron/platform-infra/commit/79576b3dbe77fcd6331c3298d42d658132f201a9))
* **tofu:** bootstrap state bucket and GitHub OIDC roles ([5e6da34](https://github.com/Taelron/platform-infra/commit/5e6da34ba70843ffeaf49b70d9eae336df3302d8))
* **tofu:** budget and backup buckets ([7695539](https://github.com/Taelron/platform-infra/commit/7695539d910f8c322ef3f3417282a8808cd3c022))
* **tofu:** Component tag in tofu/docs and tofu/bootstrap ([7a39923](https://github.com/Taelron/platform-infra/commit/7a39923fb7b2cee96cb908afc9a701e7f5cf917c))
* **tofu:** GitHub settings in code, apply environment renamed aws-apply ([0c46f89](https://github.com/Taelron/platform-infra/commit/0c46f89679cdedd0de49ec04496f0b3d92deb0b7))
* **tofu:** platform network ([3e28ddc](https://github.com/Taelron/platform-infra/commit/3e28ddce622b6e8f3769060d9480277db51c0f96))
* **tofu:** Taelron Docs hosting in a new root tofu/docs ([dcd082e](https://github.com/Taelron/platform-infra/commit/dcd082e874947e505cbdea28533eb8730ca686c3))
* **toolchain:** squash merge only, release-please per layer (Part of TAE-137) ([#23](https://github.com/Taelron/platform-infra/issues/23)) ([55891bc](https://github.com/Taelron/platform-infra/commit/55891bc8d3aa066036de6a31fb20767d3dc85234))


### Bug Fixes

* **ci:** keyed plan hash, apply-only concurrency ([a33b2b6](https://github.com/Taelron/platform-infra/commit/a33b2b6de7e1920e5f1c9db3cce635b6be6ff14c))
* **ci:** leave unchanged outputs out of the plan hash ([3c84d75](https://github.com/Taelron/platform-infra/commit/3c84d75a616c94dee532c095947e3acb46347dc5))
* **ci:** trust GitHub's immutable subject, bind the apply to the merged plan ([d6f83fb](https://github.com/Taelron/platform-infra/commit/d6f83fbee16ceec16a90338e5fede0b38b849ca8))
* **tofu:** hide the Red Hat trust policy from the plan role, deny all credential minting ([1959574](https://github.com/Taelron/platform-infra/commit/19595748d15be902f986b98c0360c78d2f50b976))
* **tofu:** narrow the plan role and tighten the apply guard ([7a2a4c3](https://github.com/Taelron/platform-infra/commit/7a2a4c3a4d27c7949a9a47c9876261f72e8a6070))
* **tofu:** plan role reads an allowlist instead of ReadOnlyAccess ([17a5c46](https://github.com/Taelron/platform-infra/commit/17a5c468993cc1966b5dc1400fdd39764bc981c7))
* **toolchain:** no approval for no-op applies, clean release titles (Part of TAE-137) ([#27](https://github.com/Taelron/platform-infra/issues/27)) ([cf9cac0](https://github.com/Taelron/platform-infra/commit/cf9cac0efbc3441cd312249936ef18c77f2b9b56))
* **toolchain:** retry the pull request lookup after a merge (Part of TAE-137) ([#28](https://github.com/Taelron/platform-infra/issues/28)) ([2564515](https://github.com/Taelron/platform-infra/commit/2564515ce72cf95c7cd93ab790465578d113f4b4))
