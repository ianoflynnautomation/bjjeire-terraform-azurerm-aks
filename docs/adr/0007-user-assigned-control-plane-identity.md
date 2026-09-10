# ADR-0007: The AKS control plane uses a user-assigned identity

- **Status:** Accepted
- **Date:** 2026-09-08 (recorded; decision predates this record)
- **Applies to:** `module.cluster_identity`, `main.aks.tf`, `var.cluster_identity_vnet_role_name`

## Context

An AKS cluster's control plane needs an Azure identity to manage the resources
it owns — in this stack, chiefly to join node pools to subnets in a VNet that
lives outside the node resource group. That requires `Network Contributor` on
the VNet.

With a system-assigned identity, the principal does not exist until the cluster
is created, so the role assignment has to be made after the fact, and it is
destroyed and recreated with the cluster. Terraform has to sequence
cluster-create → read principal → assign role, and any cluster replacement
invalidates every assignment referencing that principal.

## Decision

`managed_identities.system_assigned = false`, with a user-assigned identity
created ahead of the cluster:

```hcl
module "cluster_identity" {
  source  = "Azure/avm-res-managedidentity-userassignedidentity/azurerm"
  version = "0.5.2"
  role_assignments = {
    aks_vnet = {
      role_definition_id_or_name = var.cluster_identity_vnet_role_name
      scope                      = module.virtual_network.resource_id
    }
  }
}
```

The cluster then references it via `user_assigned_resource_ids`.

## Consequences

- The identity and its VNet role assignment outlive the cluster. Replacing the
  cluster does not require re-granting permissions, and there is no
  create-then-assign ordering problem in the graph.
- Dependency order is explicit: identity → VNet role assignment → cluster.
  `module.aks` carries `depends_on = [module.virtual_network]` for the same
  reason.
- One more resource to name and track. `cluster_identity_name_prefix` builds
  `uami-cp-<env>-<location_short_name>`.
- Deleting the identity out of band leaves the cluster unable to reconcile node
  pools, with failures that surface as node pool operations timing out rather
  than as an obvious permission error.
- Kubelet and workload identities are separate concerns — see
  [docs/architecture/identity.md](../architecture/identity.md).

## Alternatives considered

- **System-assigned identity.** One less resource, no lifecycle to manage.
  Rejected: the role assignment must be made post-create and is lost on cluster
  replacement, and Terraform cannot express the ordering cleanly.
- **Granting the control plane a broader role at resource-group scope.** Would
  avoid the VNet-scoped assignment but widens the blast radius well past what
  joining subnets needs.
