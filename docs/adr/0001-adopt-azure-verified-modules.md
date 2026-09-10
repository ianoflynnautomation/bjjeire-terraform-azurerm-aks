# ADR-0001: Provision Azure resources through Azure Verified Modules

- **Status:** Accepted
- **Date:** 2026-09-08 (recorded; decision predates this record)
- **Applies to:** every `module` block in the root module that targets an Azure resource

## Context

The stack provisions a resource group, AKS cluster and agent pools, VNet with
three subnets, NAT Gateway, private DNS zone, Key Vault, two storage accounts,
an NSG, and a set of user-assigned managed identities. Written as raw
`azurerm_*` resources, each of those carries its own diagnostic settings, role
assignment plumbing, private endpoint wiring, and secure-default choices that
have to be re-derived and re-reviewed every time.

Microsoft publishes [Azure Verified Modules](https://azure.github.io/Azure-Verified-Modules/)
covering all of these, with secure defaults, a consistent interface for
`role_assignments` / `private_endpoints` / `diagnostic_settings`, and a
published support commitment.

## Decision

Every heavyweight Azure resource is provisioned through an AVM module, pinned
by registry `source` plus an **exact** `version`:

```hcl
module "key_vault" {
  source  = "Azure/avm-res-keyvault-vault/azurerm"
  version = "0.11.0"
}
```

Currently in use: `avm-res-resources-resourcegroup` 0.4.0,
`avm-res-containerservice-managedcluster` 0.8.3 (plus its `agentpool`
submodule), `avm-res-network-virtualnetwork` 0.22.2,
`avm-res-network-natgateway` 0.3.2, `avm-res-network-privatednszone` 0.5.0,
`avm-res-keyvault-vault` 0.11.0, `avm-res-storage-storageaccount` 0.10.0,
`avm-res-network-networksecuritygroup` 0.5.1, and
`avm-res-managedidentity-userassignedidentity` 0.5.2.

Local modules under `modules/` are reserved for providers with no mature
public equivalent — Cloudflare, Entra ID, and consumption budgets — and for
project-specific composition over an AVM module
(`modules/workload-identities/` wraps the UAMI module with `for_each`).

Version bumps arrive as Renovate PRs. `renovate.json` never auto-merges a
module PR; AVM modules are pre-1.0, so minor bumps are treated as potentially
breaking and require dependency-dashboard approval, as do all majors. A
reviewed `terraform plan` on dev gates every promotion.

## Consequences

- Security defaults, role assignment plumbing, and private endpoint wiring are
  maintained upstream rather than here.
- Upgrades become a version bump and a plan review instead of a resource
  rewrite.
- The cost is coupling to pre-1.0 modules: a minor bump can change resource
  addresses and produce a destroy/create in the plan. This is why minors need
  approval and why plans are read before merge, not after.
- Exact-version pinning (not `~>`) means the plan a reviewer approves is the
  plan that runs. Do not relax these to ranges.
- Registry sources bypass `.terraform.lock.hcl` integrity checking, which
  covers providers only. The mitigating control is the Renovate policy above,
  not the lock file.

## Alternatives considered

- **Raw `azurerm_*` resources.** Maximum control, but re-derives secure
  defaults for nine resource types and makes every upgrade a manual diff.
- **`git::` sources pinned to a commit SHA.** Gives content integrity that
  registry sources do not. Rejected: it requires resolving every release tag to
  a SHA by hand, needs a Renovate regex custom-manager to maintain, and makes
  the version a comment rather than a checked field. The review gate was judged
  a better control than the hash.
- **Community modules (e.g. `Azure/aks/azurerm`).** Broader feature surface,
  but no Microsoft support commitment and a looser update cadence than AVM.
