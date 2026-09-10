# ADR-0008: The PR-environment identity exists on dev only

- **Status:** Accepted
- **Date:** 2026-09-08 (recorded; decision predates this record)
- **Applies to:** `local.gha_pr_env_enabled`, `azurerm_role_definition.aks_pr_env_namespace_admin`, `main.identity.tf`

## Context

Preview environments — one ephemeral namespace per pull request, reconciled by
a Flux `ResourceSet` factory — are a dev-cluster capability. Staging and prod
overlays in `bjjeire-gitops` do not include the preview factory, and a Kyverno
`deny-ephemeral-envs` policy rejects those namespaces there.

Driving them needs an identity that GitHub Actions can assume **from a
`pull_request` trigger**, which is the one OIDC subject that a fork or an
untrusted contributor can influence. That identity needs enough cluster access
to create a namespace, apply workloads into it, and poll them until ready.

## Decision

`gha_pr_env` is created only when preview environments are enabled:

```hcl
gha_pr_env_enabled = coalesce(var.gha_pr_env_enabled, var.environment == "dev")
```

It defaults on for dev and off everywhere else, and can still be overridden
per environment (ADR-0005).

Its access is two assignments, both scoped to the cluster resource, never to
the subscription or resource group:

- `Azure Kubernetes Service Cluster User Role` — kubeconfig retrieval only.
- A **custom role definition**, `azurerm_role_definition.aks_pr_env_namespace_admin`,
  whose actions are set from `var.aks_pr_env_role_actions`. It is deliberately
  not `Azure Kubernetes Service RBAC Admin`, which is cluster-wide.

The federated credentials cover four subjects: `pull_request` and
`refs/heads/main` for both `bjjeire-tests` and `bjjeire`. The `bjjeire` repo has
GitHub's immutable subject format enabled, so its subjects take the
`repo:<org>@<owner_id>/<repo>@<repo_id>:…` form.

The identity is created with `count`, not a `moved` block, because a `moved`
target that is absent from the configuration is an error — and it is absent by
design on staging and prod.

## Consequences

- A pull request against the app or tests repo can obtain a token that reaches
  the **dev** cluster and nothing else. There is no `pull_request` subject on
  any staging or prod identity.
- The blast radius of a compromised PR is a dev namespace. It cannot reach the
  Terraform identity (`gha_terraform` federates `environment:<env>` and
  `refs/heads/main` only — never `pull_request`), and it cannot write the atest
  flake baseline (`gha_atest_history` is pinned to `refs/heads/main`).
- Enabling `gha_pr_env_enabled` on staging or prod would create a
  `pull_request`-federated identity against a production cluster. Do not set it
  without also deciding what a fork may do with it.
- `github_manage_actions_oidc` depends on this identity —
  `AZURE_CLIENT_ID` published to the app and tests repos *is* its client ID.
  A precondition in `main.github-actions.tf` fails the plan if secret
  management is on while the identity is off.
- Because it is `count`-gated, dev's first apply after this shape landed
  replaced the unindexed resource with `[0]`, taking a new role definition ID
  with it. Expected, one time.

## Alternatives considered

- **One identity for all environments.** Simplest, and would put a
  `pull_request` subject on prod. Rejected outright.
- **`Azure Kubernetes Service RBAC Admin`.** Off the shelf, no custom role to
  maintain, but grants cluster-wide admin where namespace-scoped is enough.
- **A GitHub App token instead of OIDC federation.** Reintroduces a long-lived
  credential, which is the thing workload identity federation exists to remove.
