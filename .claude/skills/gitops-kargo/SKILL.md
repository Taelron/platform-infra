---
name: gitops-kargo
description: Taelron Platform rules for platform-gitops — the repository layout, the two paths (shared and cluster definitions from main via Argo CD, test and demo only through Kargo stage branches), warehouses and stages, pinned charts and image digests, Argo CD read-only for people, secrets through External Secrets Operator from OpenBao, and one file per client tenant. Use whenever writing or reviewing Argo CD, Kargo, Cluster API or tenant definitions for the platform.
---

# GitOps with Argo CD and Kargo

> Generated from the Taelron baseline **GitOps with Argo CD and Kargo** (https://linear.app/taelron/document/gitops-with-argo-cd-and-kargo-5b1a68882791), version of 2026-11-13.
> Do not edit by hand: regenerate from the baseline. If this skill and the baseline disagree, the baseline wins.

## Layout

```
bootstrap/            the root application
clusters/             Cluster API definitions: shared, test, demo
shared/<service>/     shared's own services
platform/<service>/   services of test and demo, one values file per stage
tenants/<client>.yaml one file per client
kargo/                warehouses and stages
```

## Two paths, never mixed

- **From `main`, Argo CD direct:** shared's own services and the cluster definitions.
- **Through Kargo:** everything in test and demo. Kargo writes `stage/test` and `stage/demo`; Argo CD follows those branches.
- Never commit to `stage/*`. Only Kargo's identity may push there (branch protection).

## Warehouses and stages

- Warehouses: `platform` (versions in `main`), `fleetdesk` (GHCR), `tenants` (files in `main`).
- Stage test: promoted automatically on new freight. Stage demo: only when Gaetan promotes it.

## Versions

Helm charts to an exact version; images by digest (see the Kubernetes Deployment baseline). A version bump is a commit to `main`, never a change in a stage branch.

## Argo CD

Read-only for people. Applications sync automatically with pruning.

## Secrets

Never in Git. External Secrets Operator in each cluster reads OpenBao through its Vault provider; services consume ordinary Kubernetes Secrets. No OpenBao agent injector.

## Tenants

`tenants/<client>.yaml` holds only the short name, display name and sample data set. The ApplicationSet derives namespace, Rancher Project, FleetDesk install, Keycloak realm and address. Never a client's real data.
