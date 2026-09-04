# Manual Setup

Steps that can't or shouldn't be Terraformed. Run once per environment.

- [Prerequisites](#prerequisites)
- [Pre-apply](#pre-apply)
- [Apply](#apply)
- [Post-apply](#post-apply)
- [Ongoing](#ongoing)

---

## Prerequisites

| Tool        | Minimum version |
| ----------- | --------------- |
| `az`        | 2.60+           |
| `terraform` | 1.9.0           |
| `kubectl`   | 1.30+           |
| `flux`      | 2.4+            |

**GitHub App (`bjjeire`) repository permissions** so this stack can rewrite `AZURE_CLIENT_ID` after a UAMI recreate (otherwise pass `TF_VAR_github_token`):

| Permission | Access | Why |
| ---------- | ------ | --- |
| Secrets    | Read and write | `AZURE_CLIENT_ID` / `AZURE_TENANT_ID` / `AZURE_SUBSCRIPTION_ID` |
| Variables  | Read and write | `AKS_CLUSTER_NAME` / `AKS_RESOURCE_GROUP` / `AKS_CLUSTER_DOMAIN` |

**Roles required on the identity running `terraform apply`:**

| Scope        | Role                                                   | Why                                              |
| ------------ | ------------------------------------------------------ | ------------------------------------------------ |
| Subscription | **Owner** *(or Contributor + User Access Admin)*       | RBAC role assignments in storage / KV modules    |
| Tenant       | **Application Administrator** *(or Cloud App Admin)*   | App registration creation                        |
| Tenant       | **Security Administrator**                             | Only if `entra_diagnostics_log_analytics_workspace_id` is set |

> **Tip:** activate via PIM for the apply window only; revert when done.

---

## Pre-apply

### 1. Authenticate

```bash
az login
az account set --subscription <SUBSCRIPTION_ID>
```

### 2. Bootstrap remote state (chicken-and-egg)

The state backend can't be Terraformed by the module that uses it.

```bash
az group create -n rg-state-shared-swn-01 -l switzerlandnorth

az storage account create -n stbjjeiresharedswn01 \
  -g rg-state-shared-swn-01 -l switzerlandnorth \
  --sku Standard_LRS --kind StorageV2 \
  --min-tls-version TLS1_2 --allow-blob-public-access false

az storage container create -n tfstate \
  --account-name stbjjeiresharedswn01 --auth-mode login
```

### 3. Register resource providers

One-time per subscription.

```bash
for ns in \
    Microsoft.ContainerService \
    Microsoft.KeyVault \
    Microsoft.ManagedIdentity \
    Microsoft.Storage \
    Microsoft.Network \
    Microsoft.OperationalInsights \
    Microsoft.Insights \
    Microsoft.Authorization
do
  az provider register --namespace "$ns"
done
```

### 4. Create Entra ID security groups

Terraform reads these via `data.azuread_group` — it does **not** create them.

```bash
# AKS cluster admins (mandatory)
az ad group create \
  --display-name "grp-bjjeire-aks-admins" \
  --mail-nickname "grp-bjjeire-aks-admins" \
  --description "Members get AKS cluster-admin via Azure RBAC for Kubernetes"

az ad group member add \
  --group "grp-bjjeire-aks-admins" \
  --member-id "$(az ad signed-in-user show --query id -o tsv)"

# oauth2-proxy allowed group (optional — only if oauth2-proxy is enabled)
az ad group create \
  --display-name "grp-bjjeire-internal-users" \
  --mail-nickname "grp-bjjeire-internal-users" \
  --description "Members can sign in past oauth2-proxy"
```

### 5. Populate `terraform.tfvars`

In `environments/<env>/terraform.tfvars`, set:

```hcl
app_registration_owner_object_ids = [
  "<your-object-id>",          # az ad signed-in-user show --query id -o tsv
  "<backup-object-id>",        # second human owner — never just one
]

bjjeire_spa_redirect_uris = [
  "https://bjjeire.com",
  "http://localhost:3000",     # dev/test envs only — strip from prod
]

aks_admin_group_display_names = ["grp-bjjeire-aks-admins"]
```

> **Warning:** never commit secrets (PATs, Cloudflare tokens, passwords) to `terraform.tfvars`. Use `data.azurerm_key_vault_secret` references in `locals.tf` instead. See [Ongoing § secret rotation](#ongoing).

---

## Apply

Dev PR-env CI uses **repo-level** GitHub Actions secrets. This stack is the source of truth for `AZURE_CLIENT_ID`, `AZURE_TESTS_CLIENT_ID` / `AZURE_TESTS_CLIENT_SECRET`, `AZURE_API_SCOPE`, CF Access, and Playwright user secrets — plus `AKS_*` variables. Do **not** set `github_manage_actions_oidc = false` on dev: that is what left CI on deleted Entra apps after teardown (`AADSTS700016` / `AADSTS7000215`). Do **not** `gh secret set` as the standing process.

Until the `bjjeire` GitHub App has repository **Secrets** and **Variables** set to Read and write, pass a user token on **every** apply (otherwise the GitHub provider 403s and the secret resources never enter state):

```bash
export TF_VAR_github_token="${TF_VAR_github_token:-$(gh auth token)}"
```

One-time GitHub App change (then you can drop `TF_VAR_github_token`): GitHub → Settings → Developer settings → GitHub Apps → **bjjeire** → Permissions → Repository → **Secrets** and **Variables** → Read and write. Accept the permission request on the installation. Apply without that (or the token) now **fails plan** — that is intentional.

```bash
cd /Users/ianoflynn/Sources/bjjeire-terraform-azurerm-aks

terraform init  -backend-config=environments/dev/backend.hcl
terraform plan  -var-file=environments/dev/terraform.tfvars -out=tfplan
terraform apply tfplan
```

Then **always** re-apply the Flux bootstrap stack in the same session. It reads UAMI client IDs live into `workload-identity-config`. Skipping it leaves External Secrets on the old `EXTERNAL_SECRETS_CLIENT_ID` (`AADSTS700016` / `ClusterSecretStore` not ready):

```bash
cd /Users/ianoflynn/Sources/bjjeire-terraform-gitops-flux-bootstrap

terraform init  -backend-config=environments/dev/backend.hcl
terraform plan  -var-file=environments/dev/terraform.tfvars -out=tfplan
terraform apply tfplan
```

---

## Post-apply

### 1. Grant admin consent on app registrations

> **Requires Global Admin or Privileged Role Admin.**

```bash
API_ID=$(terraform output -raw bjjeire_api_client_id)
SPA_ID=$(terraform output -raw bjjeire_spa_client_id)
OAUTH2_ID=$(terraform output -raw oauth2_proxy_client_id)

az ad app permission admin-consent --id "$API_ID"
az ad app permission admin-consent --id "$SPA_ID"
az ad app permission admin-consent --id "$OAUTH2_ID"
```

### 2. Verify publisher domain

Adds the *Publisher verified* badge on each app registration.

Portal → App registration → **Branding & properties** → **Configure publisher domain** → add DNS TXT record → **Verify**. Repeat for the API, SPA, and oauth2-proxy apps.

### 3. Conditional Access policies

Entra ID P1 or higher. **Always start in report-only mode**, observe for one week, then enforce.

- Require phishing-resistant MFA for all admin roles
- Block legacy auth tenant-wide
- Sign-in risk policy on `bjjeire-spa-*` and `oauth2-proxy-*` *(Entra P2)*
- Exclude break-glass accounts from every policy

### 4. Break-glass accounts

- Two **cloud-only** Global Admins
- FIDO2 keys only (no password, no MFA app)
- Credentials in offline storage (sealed envelope, two locations)
- Excluded from every Conditional Access policy
- Test sign-in once per quarter

### 5. PIM eligibility

Entra ID P2. Convert these roles from *permanent active* to *eligible*:

- Global Admin
- Application Administrator
- Cloud Application Administrator

Activation: max 4 hours, MFA + business justification required. **Keep break-glass accounts as permanent active.**

### 6. Frontend env vars in CI/CD

Set as GitHub Actions repo secrets:

```
VITE_APP_MSAL_CLIENT_ID = <bjjeire_spa_client_id>
VITE_APP_MSAL_TENANT_ID = <bjjeire_spa_msal_tenant_id>
VITE_APP_MSAL_API_SCOPE = <bjjeire_api_audience>/access_as_user
```

Trigger a frontend redeploy so the new bundle is built with these values baked in.

### 7. Backfill Log Analytics workspace

Once a central LAW exists, set `entra_diagnostics_log_analytics_workspace_id` in tfvars and re-apply.

> Re-apply requires **Security Administrator** on the tenant.

### 8. Defender for Cloud plans

```bash
for plan in CloudPosture Containers KeyVaults StorageAccounts AppServices; do
  az security pricing create -n "$plan" --tier Standard
done
```

---

## Ongoing

### Access reviews *(quarterly)*

Entra ID P2. Configure recurring reviews on:

- AKS admin group (`grp-bjjeire-aks-admins`)
- oauth2-proxy allowed group (`grp-bjjeire-internal-users`)
- App registration owners list

### Secret rotation *(quarterly)*

- Terraform auto-rotates the **oauth2-proxy client secret every 90 days**. The day after rotation, tail oauth2-proxy logs to confirm ESO synced the new secret.
- Rotate any tokens that ever touched `terraform.tfvars` in plaintext: GitHub PAT (`ghcr_pat`, `github_preview_pat`), Cloudflare token, Grafana admin password. Move long-term to `data.azurerm_key_vault_secret` in `locals.tf`.
- `github_preview_pat` is required on **dev** only (Flux `ResourceSetInputProvider` for `deploy-preview` PRs). Pass via `TF_VAR_github_preview_pat`. The HMAC at `flux-preview-webhook-token` is generated by Terraform; copy it from Key Vault into the GitHub webhook secret if you publish the notification-controller hook.

### Tenant branding *(once, cosmetic)*

Portal → Entra ID → **Company branding** → upload BjjEire logo + sign-in background.
