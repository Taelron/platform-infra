# ansible

The host `platform-aws-01`'s own services (layer **core**), one role per
Platform Runbook item, Phase 4. Run first from the RHEL box over SSH; once AAP
is installed, AAP runs the same playbooks as job templates from GitHub.

## Layout

| Path                          | What                                     |
|-------------------------------|------------------------------------------|
| `ansible.cfg`                 | defaults; run from this folder           |
| `inventory/hosts.yml`         | the host, by name only                   |
| `group_vars/all/`             | every address, port and flow             |
| `playbooks/site.yml`          | every role, in order                     |
| `playbooks/<role>.yml`        | one playbook per role                    |
| `playbooks/health.yml`        | platform health check, read-only         |
| `roles/`                      | one role per Runbook item, tag = name    |
| `collections/requirements.yml`| pinned collections                       |

`inventory/group_vars` links to `group_vars`, so Ansible reads it next to the
inventory.

## Roles

| Role   | Does                                                    |
|--------|---------------------------------------------------------|
| `base` | SELinux, SSH by key, firewalld off, updates, idle stop  |
| `disks`   | data volumes by EBS ID, XFS, mounted                 |
| `network` | bridges, host addresses, forwarding, nftables        |
| `bind`    | internal zone `int.taelron.com`, forwarder           |
| `postgresql` | PostgreSQL 15, one database per consumer, pgBackRest |
| `garage`  | S3 object storage for Mimir, Loki, Tempo             |
| `haproxy` | public names, Rancher agents, health check           |
| `alloy`   | host metrics and logs (sends from Phase 5)           |
| `kvm`     | KVM and libvirt, no NAT network                      |
| `k3s_rancher` | mgmt cluster: k3s, Traefik, Rancher Manager       |
| `aap`     | AAP 2.7 containerized, RHEL box only                 |

`disks`: each volume is found by its EBS volume ID
(`/dev/disk/by-id/nvme-Amazon_Elastic_Block_Store_vol…`), never by `nvme<n>`.
An existing filesystem is never replaced, so a re-run never erases data.

`network`: the four bridges with the host at `.1`, the service addresses
`.11`–`.14` on br-mgmt, IPv4 forwarding, and the firewall. The ruleset is
generated from `nft_flows` in `group_vars/all/network.yml`, which mirrors the
design's flow table; anything not listed is dropped. Only the table
`inet taelron` is replaced, so the tables of libvirt, podman and k3s stay.
At boot `taelron-nft.service` loads it before the network and before
forwarding; the stock `nftables.service` is masked, because it flushes the
whole ruleset on reload and stop.
Loading a new ruleset arms a 120-second rollback that is cancelled only once a
new SSH connection gets through.

`bind`: BIND 9.18 on each bridge's `.1` and `127.0.0.1`, never on `eth0`. It
holds `int.taelron.com`; each cluster's ExternalDNS updates only names under
`<cluster>.int.taelron.com`, with its own TSIG key. The keys are in `pass`
(`taelron/platform/bind/<cluster>`) and read at run time; AAP passes
`bind_update_keys` from its credentials. The zone file is written once only,
since named keeps the records ExternalDNS adds. Every other name is forwarded
to the AWS resolver, without DNSSEC validation (the AWS resolver returns no
signatures); `rancher.mgmt.taelron.com` answers Rancher's host address.

`postgresql`: PostgreSQL 15 from the RHEL stream on `192.168.10.11` and
`127.0.0.1`. One database and one role of the same name per consumer
(`postgresql_databases`), each allowed only from where it runs: host
consumers from br-mgmt, the clusters from their VM over TLS (self-signed
until OpenBao issues it). Passwords are in `pass`
(`taelron/platform/postgresql/<name>`), set when a role is created. WAL is
archived to S3 with pgBackRest (bucket `platform-pgbackrest-…`, instance role,
no key), from the moment the stanza exists (before that `archive_command` is
empty, so a shutdown never waits on a failing push); full backup weekly, differential daily, both run after the next boot
when the host was stopped. pgBackRest comes from the PGDG repository, limited
to pgBackRest and its two libraries, signed by PGDG's key (fingerprint in
`group_vars`).

`garage`: Garage (S3 API) on `192.168.10.14:3900`, one node, data on the
Garage volume. It runs as a Podman container (Quadlet unit `garage`), pinned
by image digest, with host networking so the firewall's flow 9 applies, a
read-only root filesystem and no capabilities; its files carry the SELinux
type `container_file_t`. The admin API listens on `127.0.0.1:3903` only; the
role sets up the layout, one bucket and one key per consumer (read and write
on its own bucket only) through it, so no secret appears on a command line.
Secrets and keys are in `pass` (`taelron/platform/garage/…`).

`haproxy`: HAProxy on `10.20.1.10:443` for the load balancer, which ends TLS
with ACM and re-encrypts to HAProxy's self-signed certificate. Each public name
goes by its Host header to Rancher, AAP or a cluster's public gateway `.200`
(`haproxy_routes`); AAP comes before the `*.shared` rule. The load balancer's
health check, which asks for the host's own address, is answered by HAProxy
itself. Rancher agents reach `192.168.10.13:443`, passed through over TCP to
the k3s ingress. Metrics on `127.0.0.1:8405`. It adds the idle stop's HTTPS
check: a request through the load balancer in the last two minutes, other
than a health check, counts as activity; Rancher agents do not.

`alloy`: Grafana Alloy, pinned, from Grafana's RPM repository (limited to
Alloy; each package's signature checked against the pinned key). Until
Mimir and Loki exist in shared (Phase 5), `alloy_remote_enabled` is false and
Alloy sends nothing; its UI stays on `127.0.0.1:12345`.

`kvm`: KVM and libvirt (modular daemons, started by their sockets). libvirt's
default NAT network is removed: the cluster VMs use the four bridges only.

`k3s_rancher`: the mgmt cluster. k3s (pinned binary, checksum) on its
PostgreSQL database, data on the k3s volume, SELinux enforcing with
`k3s-selinux` (Rancher's RPM repository, limited to it, package signatures
checked), secrets encryption on, no bundled load balancer. Traefik runs on
the host network on `127.0.0.1:8443` only; HAProxy sends Rancher's name and
the Rancher agents there. cert-manager and Rancher Manager are Helm charts
that k3s applies from `/var/lib/rancher/k3s/server/manifests`. Rancher has its
own certificate authority. The k3s token, the database password and Rancher's
first admin password (break-glass) are in `pass`; on the host they are in
root-only files (`/etc/rancher/k3s/config.yaml`, the Rancher manifest).

`aap`: AAP 2.7, containerized, growth topology (every component on the host:
gateway, controller, hub, EDA, metrics service), on the shared PostgreSQL. It
runs from the RHEL box only, never as an AAP job, and is not in `site.yml`.
The online installer is downloaded from Red Hat to `~/Downloads` on the RHEL
box; set `aap_installer_file` and `aap_installer_sha256` in
`group_vars/all/aap.yml`. AAP runs rootless as user `aap`, home
`/var/lib/aap/aap` on the AAP volume (labelled like `/home`), with linger.
The user has passwordless sudo only while the installer runs. The installer
runs again only when its inventory or archive changes, or when the gateway
does not answer. Envoy, AAP's entry, is on 9443 for HAProxy; no AAP listener
has a bind address, so nftables keeps the rest out. Secrets in `pass`: the
admin passwords (`taelron/platform/aap/`), the database passwords, the
Registry Service Account (`taelron/redhat/registry`: username, then token) and
the subscription manifest in base64 (`taelron/redhat/aap-manifest`).

`base` details: it checks that RHEL is registered; keeps SELinux enforcing;
masks firewalld (nftables manages the firewall); allows SSH by key only, no
root; applies security updates daily with `dnf-automatic` (no automatic
reboot); keeps the journal on disk (at most 1 GB); installs the pinned Amazon SSM
Agent for Session Manager; and installs
the idle stop. The idle stop powers the host off after `idle_stop_minutes`
(60) with no SSH session (open now, or opened or closed in the last two
minutes) and no HTTPS activity; programs in
`/etc/platform-idle/activity.d/` report other activity (HAProxy adds one).
Set `idle_stop_enabled: false` for the dates of a client trial.

## Run from the RHEL box

The host's SSH address is not in Git. `~/.ssh/config` on the RHEL box:

```
Host platform-aws-01
  HostName <Elastic IP 1, from tofu/platform output>
  User ec2-user
  IdentityFile ~/.ssh/taelron-platform
```

The key's passphrase is in `pass` (`taelron/ssh/platform-passphrase`); load the
key into `ssh-agent` first. Then, from this folder:

```
ansible-galaxy collection install -r collections/requirements.yml -p collections
ansible-playbook playbooks/site.yml --check --diff
ansible-playbook playbooks/site.yml
```

One role only: `ansible-playbook playbooks/base.yml`, or `--tags base`.
Every change runs with `--check --diff` first; its output goes in the pull
request. The first real run waits for Gaetan's go.

## Health check

```
ansible-playbook playbooks/health.yml
```

Read-only; it changes nothing, also under `--check`. One line per check:

| State    | Means                                          |
|----------|------------------------------------------------|
| OK       | works                                          |
| EXPECTED | route whose service is not built yet           |
| FAIL     | broken; the playbook fails and names it        |

It checks SELinux, the nftables table, the data volumes, the units in
`health_units`, BIND, PostgreSQL (TLS, WAL archiving, last pgBackRest
backup), Garage, the host's certificates, k3s and its deployments, each
HAProxy backend, and each public name through the load balancer, from the
machine running the playbook. Routes listed in `health_not_built`
(`group_vars/all/health.yml`) show EXPECTED while they answer 503; remove a
name when its service is built, and a check says so once it answers.
Asking the public names counts as activity for the idle stop.
