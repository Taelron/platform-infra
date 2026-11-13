---
name: platform-workflow
description: How Claude Code works on the Taelron Platform (Linear project P-TAE-13) — Linear as source of truth, one issue per runbook phase, pull requests per step, reporting in the issue, nothing applied without Gaetan, secrets only from pass, and when to ask. Use at the start of any work in platform-infra or platform-gitops, and before opening a pull request or reporting progress.
---

# Platform Workflow

> Generated from the Taelron baseline **Platform Workflow** (https://linear.app/taelron/document/platform-workflow-0fab271ff83e), version of 2026-11-13.
> Do not edit by hand: regenerate from the baseline. If this skill and the baseline disagree, the baseline wins.

The platform follows this light workflow, not the AI Build Workflow: one issue per runbook phase, no ADRs, no milestones, no Grafana tracing.

## Before any work

- Read, in Linear project P-TAE-13: the phase's issue, the **Platform Runbook**, and **Platform Design Decisions**.
- If the code would contradict a decision, stop and say so in the issue. Never diverge silently.

## Pull requests

- Work on the issue's branch name.
- One pull request per coherent step. Description: what changes, the plan or diff summary, how it was tested, the issue key.

## Reporting

Comment in the phase's issue when work starts, for each pull request, for each blocker, and at the end with the evidence for the phase's "done when".

## Nothing applies without Gaetan

- OpenTofu applies only through GitHub Actions, after his approval.
- The Ansible bootstrap runs only on his go.
- Never write to `stage/*` branches.
- Never change anything by clicking in a console; anything clicked by hand is written back into code.

## Secrets

- Read from `pass` at run time only.
- Never in a file, Git, shell history, a pull request or Linear. No AWS access keys.
- No client names. When an example needs one: Contosso Energy.

## When to ask Gaetan

Only for what he decides: extra cost, deleting data or a volume, a new public name, a network flow not in the design. Everything a baseline settles is settled without him.
