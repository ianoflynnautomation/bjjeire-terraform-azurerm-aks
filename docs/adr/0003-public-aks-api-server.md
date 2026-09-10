# ADR-0003: Keep the AKS API server public, with authorized IP ranges in prod

- **Status:** Accepted
- **Date:** 2026-09-08 (recorded; decision predates this record)
- **Applies to:** `var.aks_private_cluster_enabled`, `var.aks_api_server_authorized_ip_ranges`, `main.aks.tf`

## Context

Two things outside the VNet need to reach the Kubernetes API:

1. GitHub-hosted `terraform plan` / `apply`, which reads cluster state and
   creates the PR-environment role definition scoped to the cluster.
2. The preview-environment CI in `bjjeire` and `bjjeire-tests`, whose
   `wait-ready` step polls workloads in an ephemeral namespace on the dev
   cluster using the `gha_pr_env` identity.

A private cluster puts the API server behind a private endpoint reachable only
from the VNet or a peered network. Neither caller has a route there, and
neither has a stable source address that could be allowlisted.

## Decision

`aks_private_cluster_enabled` stays `false`. Exposure is narrowed by
`api_server_access_profile.authorized_ip_ranges` instead of by making the
endpoint private.

Dev and staging leave the ranges open. **Prod must set them**, and this is
enforced in HCL rather than by convention —
`variables.aks.tf` carries a validation that fails the plan outright:

```
Production public AKS API servers must set aks_api_server_authorized_ip_ranges
to at least one CIDR, or enable aks_private_cluster_enabled.
```

A second validation rejects entries that are not valid CIDR prefixes.

Authentication is independent of network exposure and is where the real control
sits: Entra-managed Azure RBAC (`aad_profile.enable_azure_rbac`), local
accounts disabled (`disable_local_accounts = true`) in every environment, so
there is no cluster-admin kubeconfig to steal.

## Consequences

- The API server endpoint is resolvable from the internet in dev and staging.
  Unauthenticated requests get nothing: there are no local accounts, and every
  request is an Entra token check.
- `environments/prod/terraform.tfvars` currently has the CIDR line commented
  out. That is deliberate fail-closed behaviour — a prod plan will not run
  until real operator/VPN/NAT ranges are filled in. Do not "fix" it by
  deleting the validation.
- Making the cluster private later means solving CI connectivity first
  (self-hosted runners in the VNet, or an API server VNet-integration path).
  Flipping `aks_private_cluster_enabled` alone will break `terraform plan` on
  the next run and every preview-environment `wait-ready` job.
- Node egress is unaffected by this decision: node subnets have
  `default_outbound_access_enabled = false` and SNAT through the NAT Gateway.

## Alternatives considered

- **Private cluster + self-hosted runners.** The correct end state if the
  operational cost is ever justified. Rejected today for the same reason as
  ADR-0002: it makes the CI that builds the cluster depend on the cluster.
- **Private cluster + API Server VNet Integration.** Narrows the exposure
  without a jumpbox, but still leaves GitHub-hosted runners without a route.
- **Allowlisting GitHub hosted-runner ranges.** Large, frequently changed, and
  would need a scheduled sync job. Adds little on top of Entra RBAC.
