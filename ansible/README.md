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

`base` details: it checks that RHEL is registered; keeps SELinux enforcing;
masks firewalld (nftables manages the firewall); allows SSH by key only, no
root; applies security updates daily with `dnf-automatic` (no automatic
reboot); installs the pinned Amazon SSM Agent for Session Manager; and installs
the idle stop. The idle stop powers the host off after `idle_stop_minutes`
(60) with no SSH session and no HTTPS activity; programs in
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
