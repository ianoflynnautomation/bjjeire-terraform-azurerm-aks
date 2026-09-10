# Environments

One root module, three environments, zero per-environment code. Every
difference lives in `environments/<env>/terraform.tfvars`; flat variables
([ADR-0005](../adr/0005-flat-variables-over-object-inputs.md)) are what make
that possible. All three run in Sweden Central.

## Topology

| | Dev | Staging | Prod |
|---|---|---|---|
| Resource group | `rg-bjjeire-dev-sdc-01` | `rg-bjjeire-stg-sdc-01` | `rg-bjjeire-prod-sdc-01` |
| Cluster | `aks-bjjeire-dev-sdc-01` | `aks-bjjeire-stg-sdc-01` | `aks-bjjeire-prod-sdc-01` |
| Domain | `dev.bjjeire.com` | `staging.bjjeire.com` | `bjjeire.com` |
| Key Vault | `kv-bjjeire-dev-sdc-01` | `kv-bjjeire-stg-sdc-01` | `kv-bjjeire-prod-sdc-01` |
| VNet | `10.20.0.0/16` | `10.30.0.0/16` | `10.40.0.0/16` |
| System pool | `D2pds_v5` · 2–2 | `D2pds_v5` · 1–3 | `D4pds_v5` · 2–3 |
| Kubernetes | 1.34.7 | 1.34.7 | 1.34.7 |
| PR-env identity / Flux previews | On | Off | Forbidden |
| Playwright user + CF tests token | On | Typically on | Forced off |
| Atest history account | On | Opt-in | Opt-in |
| KV firewall | Allow | Allow | Deny + `ip_rules` |
| API server CIDRs | Open | Open | **Required** |
| GitHub Environment reviewers | None | Yes | Yes |
| Deployment branch policy | Any branch | Protected only | Protected only |

The `apps` and `runners` user pools are identical across environments —
`Standard_D2ps_v6` (1–3) and `Standard_D2ds_v6` Spot (0–1).

## Fail-closed prod

Three things are enforced in HCL rather than by convention, so a
misconfiguration fails at plan time:

- **API server CIDRs.** `variables.aks.tf` rejects a prod plan where
  `aks_api_server_authorized_ip_ranges` is empty and the cluster is not
  private. `environments/prod/terraform.tfvars` ships with the line commented
  out on purpose — fill in real operator/VPN/NAT ranges before applying prod.
- **Local kube accounts** are disabled in every environment
  (`aks_local_account_disabled = true`), so there is no admin kubeconfig.
- **Playwright test user** is forced off; the Cloudflare Access tests service
  token cannot be enabled on prod.

## Dev-only capabilities

The PR-environment identity, the Flux preview `ResourceSet` factory, and the
GitHub Actions secret management (`github_manage_actions_oidc`) all default on
for dev and off elsewhere, via `coalesce(var.x, var.environment == "dev")` so
they remain overridable. See
[ADR-0008](../adr/0008-pr-environment-identity-is-dev-only.md).

## State

Each environment has its own state key in a shared account outside the cluster
resource groups:

```hcl
# environments/dev/backend.hcl
resource_group_name  = "rg-state-shared-swn-01"
storage_account_name = "stbjjeiresharedswn01"
container_name       = "tfstate"
key                  = "dev.tfstate"
use_oidc             = true
use_azuread_auth     = true
```

No account keys — the backend authenticates as the caller (`gha_terraform` in
CI, your `az login` identity locally). Blob leases provide state locking.

## Adding an environment

1. Create `environments/<env>/` with `backend.hcl` and `terraform.tfvars`.
2. Set `environment = "<env>"` — several defaults key off it.
3. Apply once from a laptop to create the `gha_terraform` identity and the
   GitHub Environment.
4. Add `TF_VAR_*` secrets to that GitHub Environment.
5. Follow [docs/runbooks/setup.md](../runbooks/setup.md) for the rest.

## Promotion

Always **dev → staging → prod**. Staging and prod apply through
`workflow_dispatch` with GitHub Environment reviewers, never from a laptop and
never from a branch that has not been through dev.
