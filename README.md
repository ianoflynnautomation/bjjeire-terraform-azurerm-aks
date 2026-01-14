# Azure AKS Terraform Module

Terraform module for deploying Azure Kubernetes Service (AKS) with Flux GitOps configuration.

## Infrastructure

**Provisioned resources:**
- AKS cluster with workload identity and OIDC issuer
- Virtual network with system and workload subnets
- Azure Key Vault with RBAC assignments
- User-assigned managed identities with federated credentials for:
  - Cluster control plane
  - Flux source controller
  - External Secrets Operator
  - Observability stack
  - GitHub Actions Runner Controller (ARC)

**Node pools:**
- System pool on default subnet (Azure CNI)
- Workload pool with Spot instances for GitHub runners

## Prerequisites

- Azure CLI authenticated
- Terraform >= 1.9.0
- kubectl
- Flux CLI

## Usage

```bash
# Initialize backend
terraform init -backend-config=environments/dev/backend.hcl

# Plan
terraform plan -var-file=environments/dev/terraform.tfvars -out=tfplan.dev

# Apply
terraform apply tfplan.dev
```

## Environments

Environment-specific configuration in `environments/{dev,staging,prod}/`:
- `backend.hcl` - Remote state configuration
- `terraform.tfvars` - Environment variables

## Key Vault Secrets

Automatically provisioned:
- `aks-ssh-public-key` / `aks-ssh-private-key`
- `gh-flux-aks-token`
- `grafana-admin-password`
- `sops-encryption-key` (Azure Key Vault key)

## CI/CD

GitHub Actions workflow validates PRs:
- Format check (`terraform fmt`)
- Environment-specific validation (dev/staging/prod)

See [.github/workflows/terraform-pr.yaml](.github/workflows/terraform-pr.yaml)

## Outputs

| Name | Description |
|------|-------------|
| `system_subnet_id` | System subnet resource ID |
| `workload_subnet_id` | Workload subnet resource ID |
| `kv_uri` | Key Vault URI |
| `workload_identity_client_id` | Cluster control plane identity client ID |
| `sops_key_id` | SOPS encryption key ID |

## License

See [LICENSE](LICENSE)
