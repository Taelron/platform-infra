# Changelog

## [1.1.0](https://github.com/Taelron/platform-infra/compare/core-v1.0.0...core-v1.1.0) (2026-11-28)


### Features

* **core:** Alloy on the host sends to Mimir and Loki in shared (Part of TAE-139) ([#103](https://github.com/Taelron/platform-infra/issues/103)) ([9a2b2dc](https://github.com/Taelron/platform-infra/commit/9a2b2dcb0fda6e36ef12e284558f110a7a4b7380))
* **core:** apply a cluster definition from platform-gitops to mgmt (Part of TAE-139) ([#86](https://github.com/Taelron/platform-infra/issues/86)) ([83a0643](https://github.com/Taelron/platform-infra/commit/83a0643f02ef34f931d4da4f30a825150a6dbc3a))
* **core:** apply shared with kube-proxy replacement and no Traefik (Part of TAE-139) ([#96](https://github.com/Taelron/platform-infra/issues/96)) ([7247515](https://github.com/Taelron/platform-infra/commit/7247515b1d89a14bfd4c78bf4217eaacf02927b1))
* **core:** apply shared's node replacement, VM with ACPI (Part of TAE-139) ([#101](https://github.com/Taelron/platform-infra/issues/101)) ([daf0974](https://github.com/Taelron/platform-infra/commit/daf09745fc6c4fc4471eb69957169edb77c0543f))
* **core:** Argo CD in shared, installed once, then managing itself (Part of TAE-139) ([#93](https://github.com/Taelron/platform-infra/issues/93)) ([0ee4de9](https://github.com/Taelron/platform-infra/commit/0ee4de9e91b1606fab2c29065427b7ccf3edf25f))
* **core:** BIND lets each update key transfer the internal zone (Part of TAE-139) ([#99](https://github.com/Taelron/platform-infra/issues/99)) ([54c7b95](https://github.com/Taelron/platform-infra/commit/54c7b9501985db82fd979506b781a41bffed5455))
* **core:** CAPLV user, storage pools and the Leap Micro image; narrower cluster access (Part of TAE-139) ([#80](https://github.com/Taelron/platform-infra/issues/80)) ([abf8f04](https://github.com/Taelron/platform-infra/commit/abf8f04ff50c7919e0377f744676a3a6706a254c))
* **core:** CAPLV v0.2.1-taelron.3, cluster VMs autostart (Part of TAE-139) ([#95](https://github.com/Taelron/platform-infra/issues/95)) ([cdf694c](https://github.com/Taelron/platform-infra/commit/cdf694c6ed0da5f404f86bab19ad04510d16a153))
* **core:** Cluster API providers CAPRKE2 and CAPLV in mgmt (Part of TAE-139) ([#83](https://github.com/Taelron/platform-infra/issues/83)) ([69a2604](https://github.com/Taelron/platform-infra/commit/69a26043582062ec52e844004600e5bd513a7071))
* **core:** cluster bridges as libvirt networks with DHCP, NAT and their flows (Part of TAE-139) ([#79](https://github.com/Taelron/platform-infra/issues/79)) ([8df4d8a](https://github.com/Taelron/platform-infra/commit/8df4d8aaa5ae7a605af1f63d79c31a9d080ea79a))
* **core:** flow 23, mgmt pods to the clusters' API addresses (Part of TAE-139) ([#90](https://github.com/Taelron/platform-infra/issues/90)) ([f67417b](https://github.com/Taelron/platform-infra/commit/f67417bedce47b9ff56780f269b14921595d7d9b))
* **core:** Grafana's database password and admin in OpenBao (Part of TAE-139) ([#102](https://github.com/Taelron/platform-infra/issues/102)) ([fb0038a](https://github.com/Taelron/platform-infra/commit/fb0038a1da1c01c9cd3b5281db83a07eea03d713))
* **core:** libvirt-guests shuts the cluster VMs down cleanly at every host stop (Part of TAE-139) ([#100](https://github.com/Taelron/platform-infra/issues/100)) ([f4aefdd](https://github.com/Taelron/platform-infra/commit/f4aefddbd7698f92f3833c6240f5730942513644))
* **core:** OpenBao database and bootstrap Secrets for shared (Part of TAE-139) ([#94](https://github.com/Taelron/platform-infra/issues/94)) ([3732c5c](https://github.com/Taelron/platform-infra/commit/3732c5c311a957ab41762ab484cd18bbbea972f0))
* **core:** OpenBao initialisation and bootstrap secrets in shared (Part of TAE-139) ([#97](https://github.com/Taelron/platform-infra/issues/97)) ([f80e8ef](https://github.com/Taelron/platform-infra/commit/f80e8ef2200ea4d86eb0dd3af163262b3f18862b))


### Bug Fixes

* **core:** CAPLV forwards the libvirt socket only (Part of TAE-139) ([#81](https://github.com/Taelron/platform-infra/issues/81)) ([2fc8c26](https://github.com/Taelron/platform-infra/commit/2fc8c264419aa12a70dffc9e5776e30758b9b595))
* **core:** CAPLV known_hosts lines built by a plain loop (Part of TAE-139) ([#88](https://github.com/Taelron/platform-infra/issues/88)) ([753e21f](https://github.com/Taelron/platform-infra/commit/753e21f0b87f6611649f7f6934916910a94e1c38))
* **core:** CAPLV may forward the libvirt socket; caplv opens no IP connection (Part of TAE-139) ([#89](https://github.com/Taelron/platform-infra/issues/89)) ([9357950](https://github.com/Taelron/platform-infra/commit/9357950a1df6c9d2a4e025fde2a0ff3ff68fa3db))
* **core:** CAPLV patch as an RFC 6902 JSON patch (Part of TAE-139) ([#85](https://github.com/Taelron/platform-infra/issues/85)) ([9c1c91a](https://github.com/Taelron/platform-infra/commit/9c1c91a1f063d70ae37a5b3710ba566a5052d3e5))
* **core:** CAPLV v0.2.1-taelron.2, image with tag and digest (Part of TAE-139) ([#84](https://github.com/Taelron/platform-infra/issues/84)) ([fa02627](https://github.com/Taelron/platform-infra/commit/fa02627d9fb1bc731e6d4ef3ab0c61e7a50ea216))
* **core:** every host key in CAPLV known_hosts (Part of TAE-139) ([#87](https://github.com/Taelron/platform-infra/issues/87)) ([d5e0993](https://github.com/Taelron/platform-infra/commit/d5e09935abf6e08a0fa603327c101a89d1e0f082))
* **core:** k3s_rancher Secrets as data, so a run changes nothing (Part of TAE-139) ([#92](https://github.com/Taelron/platform-infra/issues/92)) ([780c93e](https://github.com/Taelron/platform-infra/commit/780c93ed976a797bdfc2664bab5b70b0c4cfb511))
* **core:** M5 volumes, Garage at 45 GB, pgBackRest restore playbook (Part of TAE-139) ([#73](https://github.com/Taelron/platform-infra/issues/73)) ([b2d6b15](https://github.com/Taelron/platform-infra/commit/b2d6b15c28965d7641182959eb63cfb070fa8d42))
* **core:** PKI role shared accepts cert-manager's requests (Part of TAE-139) ([#98](https://github.com/Taelron/platform-infra/issues/98)) ([87a7056](https://github.com/Taelron/platform-infra/commit/87a70569a0ccba07ddcf504bc73d1ca021bf20be))
* **core:** Rancher's name resolves to its Service inside mgmt (Part of TAE-139) ([#91](https://github.com/Taelron/platform-infra/issues/91)) ([0709297](https://github.com/Taelron/platform-infra/commit/0709297d0f115d9e94e1d0453373f4e381fca3ec))

## 1.0.0 (2026-11-17)


### Features

* **core:** aap (Part of TAE-138) ([#54](https://github.com/Taelron/platform-infra/issues/54)) ([1ec4739](https://github.com/Taelron/platform-infra/commit/1ec4739e6e6a225207c88d130ee2709994b17f95))
* **core:** aap project and job templates (Part of TAE-138) ([#65](https://github.com/Taelron/platform-infra/issues/65)) ([b61df7d](https://github.com/Taelron/platform-infra/commit/b61df7daa4be00c313236962661e2a32f5b71746))
* **core:** aap ssh key for the host, flow 18 (Part of TAE-138) ([#60](https://github.com/Taelron/platform-infra/issues/60)) ([f0ccf9b](https://github.com/Taelron/platform-infra/commit/f0ccf9bf2f49b0a7f67222055b3d87958329a4ac))
* **core:** ansible skeleton and base role (Part of TAE-138) ([#34](https://github.com/Taelron/platform-infra/issues/34)) ([9d800e0](https://github.com/Taelron/platform-infra/commit/9d800e03c688ff3226afacfe8f91ed4921d58df7))
* **core:** bind role (Part of TAE-138) ([#39](https://github.com/Taelron/platform-infra/issues/39)) ([574164c](https://github.com/Taelron/platform-infra/commit/574164c5e93e1e7cfee621dbbeb3a44bc2fb5f8d))
* **core:** copy core secrets from pass to ssm (Part of TAE-138) ([#63](https://github.com/Taelron/platform-infra/issues/63)) ([02cecdb](https://github.com/Taelron/platform-infra/commit/02cecdbae8f1a9aab86c477720eb021b53f72bfe))
* **core:** disks and network roles (Part of TAE-138) ([#37](https://github.com/Taelron/platform-infra/issues/37)) ([d058884](https://github.com/Taelron/platform-infra/commit/d058884b41fe013c0b89dd63717f849ecf366e5e))
* **core:** garage role (Part of TAE-138) ([#44](https://github.com/Taelron/platform-infra/issues/44)) ([2b736eb](https://github.com/Taelron/platform-infra/commit/2b736ebe431f6c354206d8ff1795cc72322f76ae))
* **core:** haproxy and alloy roles (Part of TAE-138) ([#46](https://github.com/Taelron/platform-infra/issues/46)) ([d0e9d56](https://github.com/Taelron/platform-infra/commit/d0e9d56ea422ca080657bbae2e2fbba870d6264d))
* **core:** k3s and rancher role (Part of TAE-138) ([#51](https://github.com/Taelron/platform-infra/issues/51)) ([dee3c5f](https://github.com/Taelron/platform-infra/commit/dee3c5f37d7dc78f00fd467b77543d89fc9b8055))
* **core:** kvm role, k3s flows, haproxy backend checks (Part of TAE-138) ([#50](https://github.com/Taelron/platform-infra/issues/50)) ([3ae2d0d](https://github.com/Taelron/platform-infra/commit/3ae2d0d9614c8b24fcc2fd0c4c447e04cbf007fe))
* **core:** platform health check (Part of TAE-138) ([#53](https://github.com/Taelron/platform-infra/issues/53)) ([ff5038a](https://github.com/Taelron/platform-infra/commit/ff5038a9bc653059dbf634a59f48955d53fad784))
* **core:** postgresql role with pgbackrest (Part of TAE-138) ([#41](https://github.com/Taelron/platform-infra/issues/41)) ([b87c3b0](https://github.com/Taelron/platform-infra/commit/b87c3b090a15bbd6536634d7afb9c7d467890062))
* **core:** set rancher server-url (Part of TAE-138) ([#52](https://github.com/Taelron/platform-infra/issues/52)) ([9cf472d](https://github.com/Taelron/platform-infra/commit/9cf472d9d7dfcfd1cd6595550378e84174998bfc))


### Bug Fixes

* **core:** aap eda api off traefik's port 8000 (Part of TAE-138) ([#57](https://github.com/Taelron/platform-infra/issues/57)) ([9e78dc0](https://github.com/Taelron/platform-infra/commit/9e78dc0ed43aaf38c967f665392790f4539aa689))
* **core:** aap install sudo rule rejected by visudo (Part of TAE-138) ([#55](https://github.com/Taelron/platform-infra/issues/55)) ([c920d20](https://github.com/Taelron/platform-infra/commit/c920d208a5faff20139de6a666cf7a060e34b785))
* **core:** aap organisation gets the galaxy credential (Part of TAE-138) ([#67](https://github.com/Taelron/platform-infra/issues/67)) ([236331c](https://github.com/Taelron/platform-infra/commit/236331cf346c1863e16ef765bd24f9a3b1d3f6f1))
* **core:** aap trusts the postgresql certificate (Part of TAE-138) ([#56](https://github.com/Taelron/platform-infra/issues/56)) ([4828079](https://github.com/Taelron/platform-infra/commit/4828079db382edc05426bbe48c7dda9f89d3f547))
* **core:** aap volume label reads semanage's stdout (Part of TAE-138) ([#59](https://github.com/Taelron/platform-infra/issues/59)) ([a84e0d8](https://github.com/Taelron/platform-infra/commit/a84e0d8885e9f45f6b725c52e3e23b29c1b3125f))
* **core:** aap volume label reports no change when set (Part of TAE-138) ([#58](https://github.com/Taelron/platform-infra/issues/58)) ([91a6201](https://github.com/Taelron/platform-infra/commit/91a62010ab1134b0670f9e3a3119337f87edd08c))
* **core:** bind forwards without DNSSEC validation (Part of TAE-138) ([#40](https://github.com/Taelron/platform-infra/issues/40)) ([940af34](https://github.com/Taelron/platform-infra/commit/940af34ab7fdcd1b85f7cc8cec2ba87f43ec238a))
* **core:** create the garage folder before labelling it (Part of TAE-138) ([#45](https://github.com/Taelron/platform-infra/issues/45)) ([f05c91f](https://github.com/Taelron/platform-infra/commit/f05c91ff641370a29a351f18eef4b599d85bb111))
* **core:** firewall before forwarding, own nftables unit (Part of TAE-138) ([#38](https://github.com/Taelron/platform-infra/issues/38)) ([def994a](https://github.com/Taelron/platform-infra/commit/def994a1834c9307d861787885dc5ba8e7609ce3))
* **core:** idle stop counts short SSH sessions, journal kept on disk (Part of TAE-138) ([#48](https://github.com/Taelron/platform-infra/issues/48)) ([ee7d754](https://github.com/Taelron/platform-infra/commit/ee7d7547d2e7ae10581abd69c68de25a0483192d))
* **core:** let haproxy bind its metrics port under SELinux (Part of TAE-138) ([#47](https://github.com/Taelron/platform-infra/issues/47)) ([86edf53](https://github.com/Taelron/platform-infra/commit/86edf538ed7be142920e0b3eaa85c38571f4dac4))
* **core:** let pgbackrest reach S3 under SELinux (Part of TAE-138) ([#43](https://github.com/Taelron/platform-infra/issues/43)) ([7ee5535](https://github.com/Taelron/platform-infra/commit/7ee5535b1568a264133695c44d840daa73189c23))
* **core:** move the journal to disk without a reboot (Part of TAE-138) ([#49](https://github.com/Taelron/platform-infra/issues/49)) ([72b1f54](https://github.com/Taelron/platform-infra/commit/72b1f5400d377fdd1c4d335bed32dbc63304ee0a))
* **core:** postgresql allows 1024 connections (Part of TAE-138) ([#66](https://github.com/Taelron/platform-infra/issues/66)) ([89e7fba](https://github.com/Taelron/platform-infra/commit/89e7fba95b110552899fee2f509a739079cf0060))
* **core:** start WAL archiving once the stanza exists (Part of TAE-138) ([#42](https://github.com/Taelron/platform-infra/issues/42)) ([63bd0e0](https://github.com/Taelron/platform-infra/commit/63bd0e01ce07dafe6c25664b6a943a5d79e5cda1))
