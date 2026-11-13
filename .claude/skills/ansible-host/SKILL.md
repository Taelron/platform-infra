---
name: ansible-host
description: Taelron Platform rules for configuring the host platform-aws-01 with Ansible in platform-infra/ansible — a layout AAP imports as a project, one role per runbook item, re-runnable with check and diff first, addresses and the nftables flow list only in group_vars, pinned versions, secrets from pass then OpenBao, SELinux enforcing and firewalld off. Use whenever writing, running or reviewing Ansible for the platform.
---

# Ansible Host

> Generated from the Taelron baseline **Ansible Host** (https://linear.app/taelron/document/ansible-host-002c772ddeac), version of 2026-11-13.
> Do not edit by hand: regenerate from the baseline. If this skill and the baseline disagree, the baseline wins.

## Layout (AAP imports it as a project, as is)

```
ansible/
  ansible.cfg
  inventory/
  group_vars/                    every address, port and flow
  playbooks/site.yml             + one playbook per role
  roles/                         base disks network bind postgresql garage
                                 haproxy alloy kvm k3s_rancher aap
  collections/requirements.yml
  execution-environment.yml
```

Each role carries its own tag.

## Running

- Every role converges when run again.
- A change runs with `--check --diff` first; its output goes in the pull request.
- First run from the RHEL box, on Gaetan's go; afterwards AAP job templates run the same playbooks from GitHub. The `aap` role runs from the RHEL box only.

## Addresses and flows

- From `group_vars` only, copied from **Platform Design Decisions**. No IP address inside a role.
- The nftables ruleset is generated from one flow list mirroring the design's flow table; anything not on the list is dropped.

## Versions

Collections pinned in `collections/requirements.yml`; packages pinned where the role installs a specific version (PostgreSQL 15, k3s, Rancher, AAP 2.7).

## Secrets

- Bootstrap: `pass` through the `community.general.passwordstore` lookup.
- Once OpenBao runs: read from OpenBao; in AAP, through its credentials.
- Never in `group_vars` or a vars file. `no_log: true` on every task that handles one.

## Host rules

SELinux enforcing. SSH by key only. nftables manages the firewall directly; firewalld is turned off.
