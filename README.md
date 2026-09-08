# BjjEire Platform Infrastructure

[![terraform-pipeline](https://github.com/ianoflynnautomation/bjjeire-terraform-azurerm-aks/actions/workflows/terraform-pipeline.yml/badge.svg)](https://github.com/ianoflynnautomation/bjjeire-terraform-azurerm-aks/actions/workflows/terraform-pipeline.yml)
![Terraform](https://img.shields.io/badge/terraform-%E2%89%A5%201.14-844FBA?logo=terraform&logoColor=white)
![Azure](https://img.shields.io/badge/azurerm-4.x-0078D4?logo=microsoftazure&logoColor=white)
![Cloudflare](https://img.shields.io/badge/cloudflare-5.x-F38020?logo=cloudflare&logoColor=white)
[![Renovate](https://img.shields.io/badge/renovate-enabled-1A1F6C?logo=renovate)](renovate.json)

Terraform configuration that provisions the complete Azure + Cloudflare platform for [BjjEire](https://github.com/ianoflynnautomation/bjjeire) — an AKS cluster with workload identity, edge security through Cloudflare Zero Trust, and everything Flux needs to take over from there.

## How this repo fits in

| Repository | Owns |
|------------|------|
| **bjjeire-terraform-azurerm-aks** (this repo) | Azure + Cloudflare + Entra ID infrastructure: cluster, network, identities, Key Vault, edge |
| [bjjeire-gitops](https://github.com/ianoflynnautomation/bjjeire-gitops) | Everything inside the cluster: Flux, Istio, observability, app releases |
| [bjjeire](https://github.com/ianoflynnautomation/bjjeire) | The application: API, SPA frontend, seeder |

The handoff: Terraform provisions the cluster and identities → Flux is bootstrapped against the gitops repo → Flux reconciles workloads using the workload identities and Key Vault secrets created here (via External Secrets Operator).

After **teardown + provision**, apply this stack first (it recreates UAMIs, Key Vault secrets, tunnel CNAMEs, and GitHub `AZURE_CLIENT_ID`), then re-apply [bjjeire-terraform-gitops-flux-bootstrap](https://github.com/ianoflynnautomation/bjjeire-terraform-gitops-flux-bootstrap) so `workload-identity-config` picks up the new client IDs. See **[setup.md](setup.md)**.

## Architecture

```mermaid
flowchart LR
    subgraph edge [Cloudflare Edge]
        DNS[DNS + CDN + WAF] --> Access[Zero Trust Access<br/>Entra ID IdP]
        Access --> Tunnel[Cloudflare Tunnel]
    end

    subgraph azure [Azure]
        Tunnel --> Istio[Istio ingress]
        subgraph aks [AKS]
            Istio --> Apps[bjjeire workloads]
            Runners[Spot node pool<br/>GitHub ARC runners]
        end
        Apps -- workload identity --> KV[Key Vault]
        Apps -- workload identity --> Storage[Blob Storage]
        Entra[Entra ID<br/>app registrations] -. federated credentials .-> aks
    end
```

**What gets provisioned:**

- **AKS** — [AVM managed cluster module](https://github.com/Azure/terraform-azurerm-avm-res-containerservice-managedcluster); Entra RBAC, OIDC issuer + workload identity, system pool plus a Spot pool (scale-to-zero) for GitHub Actions runners
- **Network** — VNet with system / workload / private-endpoint subnets, NAT Gateway egress (`userAssignedNATGateway`; node subnets have `default_outbound_access_enabled = false`), NSG locked to Cloudflare origin IPs. Key Vault has a private endpoint plus `privatelink.vaultcore.azure.net`; public data-plane access stays on so GitHub-hosted apply can still write secrets.
- **Cloudflare** — zone settings, WAF/cache/security-header rulesets, Tunnel (no public ingress), Zero Trust Access with Entra ID as IdP
- **Identity** — user-assigned managed identities with federated credentials for the API, seeder, Flux controllers, External Secrets, ARC test runner, and GitHub Actions OIDC (no long-lived CI secrets anywhere)
- **Key Vault** — RBAC-only (no access policies); app secrets are written here and consumed in-cluster via External Secrets
- **Entra ID** — app registrations for the API, SPA, tests, and oauth2/Access IdP flows
- **Supporting** — image storage account, resource-group budget alerts, Entra diagnostic settings

**Edge auth chain:** users hit Cloudflare Access (Entra ID at the edge) before anything reaches the tunnel; the API additionally validates JWTs via Istio. There is intentionally no oauth2-proxy in front of the frontend.

## Repository structure

```
├── main.*.tf                  # Root composition, one concern per file (aks, network, key-vault, …)
├── variables.*.tf             # Flat variables — every knob overridable from tfvars
├── outputs.tf
├── modules/
│   ├── app-registration/      # Generic, reusable primitives (singular names)
│   ├── budget/
│   ├── cloudflare-access-idp/
│   ├── cloudflare-tunnel/
│   ├── cloudflare-zone/
│   ├── entra-diagnostic-setting/
│   ├── workload-identities/   # Composition wrapper over the AVM UAMI module
│   └── bjjeire-app-registrations/  # Project-specific compositions (prefixed names)
├── environments/
│   ├── dev/                   # backend.hcl + terraform.tfvars (+ example.tfvars)
│   ├── staging/
│   └── prod/
└── .github/workflows/         # terraform-quality, terraform-audit, renovate
```

Heavyweight Azure resources use official [Azure Verified Modules](https://azure.github.io/Azure-Verified-Modules/) (resource group, AKS, VNet, NAT Gateway, Private DNS, Key Vault, Storage, NSG, managed identity), pinned by registry `version`. Cloudflare and Entra ID resources are local modules — no mature public equivalents exist for those providers.

## Prerequisites

| Tool | Version |
|------|---------|
| [Terraform](https://developer.hashicorp.com/terraform) | ≥ 1.14 |
| [Azure CLI](https://learn.microsoft.com/cli/azure/) | 2.60+ |
| [tflint](https://github.com/terraform-linters/tflint) | 0.53+ |
| kubectl / flux | for post-apply verification |

You also need Azure roles for RBAC assignments and app-registration creation, a scoped Cloudflare API token, and a handful of `TF_VAR_*` secrets (`cloudflare_api_token`, `github_app_private_key`, `ghcr_pat`, `github_preview_pat`, …). See **[setup.md](setup.md)** for the full one-time setup: required roles, secret sourcing, and post-apply steps.

## Deploying changes

Each environment is applied from the same root configuration — only the backend and tfvars differ.

```bash
# One-time per environment (laptop bootstrap — creates the gha_terraform UAMI
# and writes ARM_* onto the GitHub Environment). After that, prefer CI.
terraform init -backend-config=environments/dev/backend.hcl

export TF_VAR_github_token="${TF_VAR_github_token:-$(gh auth token)}"

terraform plan -var-file=environments/dev/terraform.tfvars -out=tfplan
terraform apply tfplan
```

**Promotion order is always dev → staging → prod.** After bootstrap, merge to `main` applies **dev** via `.github/workflows/terraform-pipeline.yml`. Staging and prod apply through `workflow_dispatch` with GitHub Environment reviewers.

CI on every PR (against the **dev** environment):

- **quality** — `fmt`, `validate`, tflint (reusable workflow in bjjeire-ci-templates)
- **iac-scan** — Trivy SARIF
- **plan** — OIDC plan; the binary plan is not uploaded (this repo is public)

## Environment strategy

One root configuration, three environments, zero per-environment code. All differences live in `environments/<env>/terraform.tfvars` — flat variables mean any setting can be overridden per environment without touching HCL. Typical differences: budget amounts, Playwright test user (dev/staging only), API authorized IP ranges, node pool sizing.

## Dependency management

Azure Verified Modules come from the Terraform Registry, pinned by `version`:

```hcl
module "key_vault" {
  source  = "Azure/avm-res-keyvault-vault/azurerm"
  version = "0.11.0"
}
```

A self-hosted [Renovate workflow](.github/workflows/renovate.yaml) keeps these fresh: the terraform manager bumps registry `version` constraints, providers are grouped for patch/minor updates, and AVM pre-1.0 minor bumps plus all majors require dashboard approval. Module PRs are never auto-merged — a reviewed plan gates every promotion.

## Extending the infrastructure

- **New resource** — prefer an AVM module if one exists (registry `source` + `version`, wrapped in a local module if it needs composition); otherwise write a minimal local module or raw resource
- **New setting** — add a flat `variable` with a sensible default so existing tfvars keep working; never bury values in objects or hardcode per-environment logic
- **New environment** — create `environments/<env>/` with `backend.hcl` and `terraform.tfvars`, then follow [setup.md](setup.md)

## Security notes

- **No standing credentials in CI** — GitHub Actions and in-cluster workloads authenticate via workload identity federation (OIDC); the ARC test runner reaches Entra the same way
- **PR-env identity is dev-only** — it federates `pull_request` and is omitted on staging/prod (Flux preview and Kyverno `deny-ephemeral-envs` are a dev-cluster capability). It uses a custom namespaced role, not cluster-wide Azure Kubernetes Service RBAC Admin
- **Prod fail-closed** — local kube accounts off, public API server must list authorized CIDRs, Playwright test user and Cloudflare Access tests token cannot be enabled
- **Key Vault is RBAC-only**; secrets flow Key Vault → External Secrets → workloads, never through pipelines. In-cluster traffic uses a private endpoint; `kv_public_network_access_enabled` stays true so GitHub-hosted terraform apply can still write secrets. Prod examples use Deny + operator/CI `ip_rules` — do not disable public access or CI apply breaks
- **Node egress is NAT Gateway** — system pool on the system subnet, user pools on the workload subnet, both NATed. The AKS API stays public (authorized CIDRs in prod); a private API would break GitHub-hosted plan/apply and PR-env wait-ready
- **Secrets never enter git** — `cloudflare_api_token`, `github_app_private_key`, `ghcr_pat`, and `github_preview_pat` come from `TF_VAR_*`; Grafana and MongoDB passwords are generated and stored in Key Vault. State files, plans, and private keys are gitignored
- **Origin lockdown** — the cluster is reachable only through the Cloudflare Tunnel; the NSG rejects non-Cloudflare traffic
- Vulnerability reports: see [SECURITY.md](SECURITY.md)

## Contributing

1. Branch from `main` (`feat/…`, `fix/…`, `chore/…`) and use [conventional commits](https://www.conventionalcommits.org/)
2. Run `terraform fmt -recursive`, `terraform validate`, and `tflint` locally before pushing
3. Open a PR — `terraform-pipeline` must pass (quality, IaC scan, and a dev plan)
4. Never apply to staging/prod from a branch that hasn't gone through dev. Staging/prod apply is `workflow_dispatch` with Environment reviewers, not a laptop apply.

## License

[MIT](LICENSE)
