# ADR-0002: Keep the Key Vault public data plane enabled

- **Status:** Accepted
- **Date:** 2026-09-08 (recorded; decision predates this record)
- **Applies to:** `var.kv_public_network_access_enabled`, `var.kv_network_acls`, `main.key-vault.tf`

## Context

`main.key-vault.tf` writes roughly two dozen secrets into Key Vault as part of
`terraform apply` — the Cloudflare tunnel token, GitHub App credentials, MSAL
client IDs, generated Grafana and MongoDB passwords, the GHCR PAT, the SOPS
key material, and the AKS SSH keypair. In-cluster consumers (External Secrets
Operator, Flux) read those secrets over a private endpoint in the
`PrivateEndpointSubnet`, resolved through the
`privatelink.vaultcore.azure.net` zone linked to the cluster VNet.

Terraform itself does not run in the cluster. It runs on GitHub-hosted
`ubuntu-latest` runners, which have no route into the VNet and no stable egress
address range. Turning off public network access closes the data plane for the
one principal that has to write to it.

Trivy and most Azure baselines flag `public_network_access_enabled = true` as a
finding. It is, on its own. Here it is load-bearing.

## Decision

`kv_public_network_access_enabled` stays `true` in all environments.

Access is narrowed by other controls rather than by closing the data plane:

- **RBAC only.** No access policies. `local.kv_role_assignments` grants exactly
  three: `Key Vault Administrator` to the apply principal, and
  `Key Vault Secrets User` to the External Secrets and Flux workload
  identities.
- **Private endpoint** for everything in-cluster, so pod traffic never uses the
  public endpoint.
- **`kv_network_acls`** carries the firewall. The prod example
  (`environments/prod/example.tfvars`) sets `default_action = "Deny"` with
  operator, VPN, and CI egress CIDRs in `ip_rules`.

## Consequences

- A reviewer or scanner will keep flagging this. That is the cost, and this ADR
  is the answer.
- **Reversing it breaks CI.** With `public_network_access_enabled = false`,
  `terraform apply` fails writing secrets — the vault's data plane rejects the
  runner. The symptom is a `403 Forbidden` on `azurerm_key_vault_secret`
  creation partway through an otherwise healthy apply, leaving the vault
  partially populated.
- Setting `default_action = "Deny"` with an **empty** `ip_rules` list is the
  same failure with a different shape: public access is nominally enabled but
  nothing can reach it. Prod tfvars must list real CIDRs.
- Secrets never travel through pipeline logs or artifacts. The path is
  Terraform → Key Vault → External Secrets → pod.

## Alternatives considered

- **Self-hosted runners inside the VNet.** Would allow closing the data plane
  entirely. Rejected for now: it makes the CI that provisions the cluster
  depend on the cluster existing, which breaks first-apply and disaster
  recovery. Revisit if a runner pool moves outside this stack's lifecycle.
- **GitHub Actions egress IP allowlist.** GitHub publishes hosted-runner ranges
  via its meta API, but they are large, change without notice, and would need a
  scheduled job to keep `ip_rules` in sync. The allowlist would be wide enough
  to add little over RBAC.
- **Writing secrets from a separate in-cluster job.** Moves the problem rather
  than solving it: something still has to seed the first secrets before the
  cluster can reconcile.
