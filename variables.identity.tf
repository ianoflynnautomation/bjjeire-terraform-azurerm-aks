variable "cluster_identity_name_prefix" {
  type        = string
  default     = "uami-cp-"
  description = "Prefix for the AKS control-plane user-assigned managed identity. Final name: <prefix><environment>-<location_short_name>."
}

variable "external_secrets_identity_name_prefix" {
  type        = string
  default     = "uami-extsecrets-"
  description = "Prefix for the external-secrets workload identity name."
}

variable "api_identity_name_prefix" {
  type        = string
  default     = "uami-bjjeire-api-"
  description = "Prefix for the bjjeire-api workload identity name."
}

variable "seeder_identity_name_prefix" {
  type        = string
  default     = "uami-bjjeire-seeder-"
  description = "Prefix for the bjjeire-seeder workload identity name."
}

variable "flux_identity_name_prefix" {
  type        = string
  default     = "uami-flux-"
  description = "Prefix for the Flux workload identity name."
}

variable "gha_pr_env_identity_name_prefix" {
  type        = string
  default     = "uami-gha-prenv-"
  description = "Prefix for the GitHub Actions PR-env workload identity name."
}

variable "tests_runner_identity_name_prefix" {
  type        = string
  default     = "uami-tests-runner-"
  description = "Prefix for the UAMI bound to the ARC runner ServiceAccount. The runner pod that executes Playwright suites authenticates to Entra as this identity via Workload Identity Federation, so no client secret needs to live in CI. Granted Tests.Invoke on the bjjeire-api app registration."
  nullable    = false
}

variable "gha_pr_env_tests_repo" {
  type        = string
  default     = "bjjeire-tests"
  description = "Name of the GitHub repository that runs PR-env workflows. Combined with var.github_org to scope federated identity credential subjects."
}

variable "gha_pr_env_main_branch" {
  type        = string
  default     = "main"
  description = "Git branch ref used as the main-branch trust boundary for the PR-env identity (refs/heads/<branch>)."
}

variable "cluster_identity_vnet_role_name" {
  type        = string
  default     = "Network Contributor"
  description = "Azure RBAC role assigned to the AKS control-plane identity on the virtual network."
}

variable "gha_pr_env_aks_user_role_name" {
  type        = string
  default     = "Azure Kubernetes Service Cluster User Role"
  description = "Azure RBAC role assigned to the GHA PR-env identity on the AKS cluster for kubeconfig issuance."
}

variable "aks_pr_env_role_name_format" {
  type        = string
  default     = "AKS PR-env Namespace Admin (%s)"
  description = "Display-name format for the custom AKS PR-env namespace admin role. %s is replaced with var.environment."
}

variable "aks_pr_env_role_description" {
  type        = string
  default     = "Allows the GitHub Actions pr-env workflow to manage ephemeral PR namespaces in AKS. Permits namespace + most namespaced-resource CRUD via Azure RBAC for Kubernetes, but cannot mutate cluster RBAC, node pools, or AKS itself."
  description = "Description of the custom AKS PR-env namespace admin role."
}

variable "aks_pr_env_role_actions" {
  type = list(string)
  default = [
    "Microsoft.ContainerService/managedClusters/read",
    "Microsoft.ContainerService/managedClusters/listClusterUserCredential/action",
  ]
  description = "Azure RBAC control-plane actions granted by the AKS PR-env namespace admin custom role."
}

variable "aks_pr_env_role_not_actions" {
  type = list(string)
  default = [
    "Microsoft.ContainerService/managedClusters/listClusterAdminCredential/action",
    "Microsoft.ContainerService/managedClusters/runCommand/action",
  ]
  description = "Explicit not_actions excluded from the AKS PR-env role (deny by subtraction)."
}

variable "aks_pr_env_role_data_actions" {
  type = list(string)
  default = [
    "Microsoft.ContainerService/managedClusters/namespaces/read",
    "Microsoft.ContainerService/managedClusters/namespaces/write",
    "Microsoft.ContainerService/managedClusters/namespaces/delete",
  ]
  description = "AKS Kubernetes-namespace data actions granted by the AKS PR-env role."
}

variable "oauth2_proxy_app_name_prefix" {
  type        = string
  default     = "oauth2-proxy-"
  description = "Prefix for the OAuth2 Proxy Entra app registration display name. Final name: <prefix><aks_cluster_name>."
}

variable "oauth2_proxy_callback_subdomain" {
  type        = string
  default     = "oauth2"
  description = "Subdomain under cluster_domain that hosts the oauth2-proxy callback (https://<subdomain>.<cluster_domain>/<path>)."
}

variable "oauth2_proxy_callback_path" {
  type        = string
  default     = "/oauth2/callback"
  description = "URI path of the oauth2-proxy OIDC callback. Combined with oauth2_proxy_callback_subdomain and cluster_domain to form the redirect URI registered on the Entra app."
}

variable "oauth2_proxy_optional_id_token_claims" {
  type        = list(string)
  default     = ["groups"]
  description = "Optional ID token claims to enable on the oauth2-proxy Entra app (e.g. groups for AuthZ)."
}

variable "oauth2_proxy_group_membership_claims" {
  type        = list(string)
  default     = ["SecurityGroup"]
  description = "group_membership_claims for the oauth2-proxy Entra app. Limits which group types appear in the groups claim."
}

variable "oauth2_proxy_secret_display_name" {
  type        = string
  default     = "oauth2-proxy-secret"
  description = "display_name of the azuread_application_password resource for oauth2-proxy."
}

variable "oauth2_proxy_secret_rotation_days" {
  type        = number
  default     = 90
  description = "Rotation period in days for the oauth2-proxy Entra app password."
}

variable "oauth2_proxy_secret_validity" {
  type        = string
  default     = "720h"
  description = "Validity window (Go duration) added to the rotation timestamp to compute the password end_date. Default 720h ≈ 30 days, giving overlap with the 90-day rotation."
}

variable "oauth2_proxy_cookie_secret_length" {
  type        = number
  default     = 32
  description = "Byte length of the random cookie secret generated for oauth2-proxy."
}

variable "github_app_id" {
  type        = string
  description = "GitHub App ID (e.g. \"123456\"). Same App is consumed by Flux source-controller (gitops reads + image-automation pushes) and Actions Runner Controller (runner registration)."
  sensitive   = true
  nullable    = false

  validation {
    condition     = can(tonumber(var.github_app_id)) && tonumber(var.github_app_id) > 0
    error_message = "github_app_id must be a positive numeric string."
  }
}

variable "github_app_installation_id" {
  type        = string
  description = "Installation ID of the shared GitHub App on the ianoflynnautomation account. Found at github.com/organizations/{org}/settings/installations/{INSTALLATION_ID}."
  sensitive   = true
  nullable    = false

  validation {
    condition     = can(tonumber(var.github_app_installation_id)) && tonumber(var.github_app_installation_id) > 0
    error_message = "github_app_installation_id must be a positive numeric string."
  }
}

variable "github_app_private_key" {
  type        = string
  description = "PEM-encoded private key for the shared GitHub App. Multi-line. Pass via TF_VAR_github_app_private_key=\"$(cat key.pem)\" rather than embedding in tfvars."
  sensitive   = true
  nullable    = false

  validation {
    condition     = startswith(trimspace(var.github_app_private_key), "-----BEGIN") && strcontains(var.github_app_private_key, "PRIVATE KEY-----")
    error_message = "github_app_private_key must be a PEM-encoded private key."
  }
}

variable "grafana_admin_password" {
  type        = string
  description = "Grafana admin password"
  sensitive   = true
  nullable    = false
}

variable "ghcr_pat" {
  type        = string
  description = "GitHub PAT with read:packages scope. Consumed by the bjj-app ghcr-pull-secret ExternalSecret to authenticate Helm/image pulls from GHCR. Pass via TF_VAR_ghcr_pat rather than embedding in tfvars."
  sensitive   = true
  nullable    = false

  validation {
    condition     = length(trimspace(var.ghcr_pat)) > 0
    error_message = "ghcr_pat must be non-empty."
  }
}

variable "github_org" {
  type        = string
  description = "The GitHub Organization or Username"
}

variable "github_repo" {
  type        = string
  description = "The repository name"
}

variable "app_registration_owner_object_ids" {
  type        = list(string)
  description = "Entra ID object IDs of users or groups that own the BjjEire API and SPA app registrations. At least two owners is recommended."
  default     = []
  nullable    = false
}

variable "playwright_test_user_enabled" {
  type        = bool
  description = "Provision a dedicated Entra user for Playwright UI tests (browser MSAL flow). Enable on dev/staging; keep off in prod."
  default     = false
  nullable    = false
}

variable "playwright_test_user_display_name" {
  type        = string
  description = "Display name of the Playwright test user. Environment is appended in parentheses."
  default     = "Playwright Test User"
  nullable    = false

  validation {
    condition     = length(trimspace(var.playwright_test_user_display_name)) > 0
    error_message = "playwright_test_user_display_name must be non-empty."
  }
}

variable "playwright_test_user_mail_nickname_prefix" {
  type        = string
  description = "Prefix for the mail_nickname (and UPN local part). Final UPN = <prefix>-<environment>@<default-domain>. Must be DNS-safe — lowercase alphanumerics and hyphens."
  default     = "playwright-test"
  nullable    = false

  validation {
    condition     = can(regex("^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?$", var.playwright_test_user_mail_nickname_prefix))
    error_message = "playwright_test_user_mail_nickname_prefix must be lowercase alphanumerics and hyphens, ≤63 chars."
  }
}

variable "app_registration_name_prefixes" {
  type = object({
    api   = string
    spa   = string
    tests = string
  })
  description = "Environment-agnostic display name prefixes for the BjjEire Entra app registrations. The environment suffix is appended in app-registrations.tf."
  default = {
    api   = "bjjeire-api"
    spa   = "bjjeire-spa"
    tests = "bjjeire-tests"
  }
  nullable = false

  validation {
    condition = (
      length(trimspace(var.app_registration_name_prefixes.api)) > 0
      && length(trimspace(var.app_registration_name_prefixes.spa)) > 0
      && length(trimspace(var.app_registration_name_prefixes.tests)) > 0
    )
    error_message = "app_registration_name_prefixes.api, .spa, and .tests must be non-empty."
  }
}

variable "microsoft_graph_resource_access" {
  type = object({
    app_id = string
    delegated_scopes = object({
      user_read = string
    })
  })
  description = "Microsoft Graph application ID and delegated permission IDs requested by BjjEire app registrations."
  default = {
    app_id = "00000003-0000-0000-c000-000000000000"
    delegated_scopes = {
      user_read = "e1fe6dd8-ba31-4d61-89e7-88639da4683d"
    }
  }
  nullable = false
}

variable "api_oauth2_permission_scopes" {
  type = map(object({
    id                         = string
    value                      = string
    type                       = optional(string, "User")
    enabled                    = optional(bool, true)
    admin_consent_description  = string
    admin_consent_display_name = string
    user_consent_description   = optional(string, null)
    user_consent_display_name  = optional(string, null)
  }))
  description = "Delegated OAuth2 permission scopes exposed by the BjjEire API app registration. Scope IDs are stable Entra IDs and must not change after consent is granted."
  default = {
    access_as_user = {
      id                         = "5f1a3c8d-3a7d-4b8e-9c2f-1a1d2e3f4a5b"
      value                      = "access_as_user"
      admin_consent_description  = "Allow the bjjeire SPA to call the bjjeire-api on behalf of the signed-in user."
      admin_consent_display_name = "Access bjjeire-api as user"
      user_consent_description   = "Access the bjjeire-api on your behalf."
      user_consent_display_name  = "Access bjjeire-api"
    }
  }
  nullable = false

  validation {
    condition = (
      contains(keys(var.api_oauth2_permission_scopes), "access_as_user")
      && alltrue([
        for scope in values(var.api_oauth2_permission_scopes) :
        contains(["User", "Admin"], scope.type)
        && length(trimspace(scope.value)) > 0
        && length(trimspace(scope.admin_consent_description)) > 0
        && length(trimspace(scope.admin_consent_display_name)) > 0
      ])
    )
    error_message = "api_oauth2_permission_scopes must include access_as_user and each scope must have type User or Admin with consent metadata."
  }
}

variable "api_app_roles" {
  type = map(object({
    id                   = string
    value                = string
    display_name         = string
    description          = string
    allowed_member_types = optional(list(string), ["User"])
    enabled              = optional(bool, true)
  }))
  description = "Application roles exposed by the BjjEire API app registration. Role IDs are stable Entra IDs and must not change after assignment. tests_invoke MUST be present — the tests SP role assignment binds against it explicitly."
  default = {
    admin = {
      id           = "b1d4e7a3-2c5b-4f6e-8d9a-3b4c5d6e7f80"
      value        = "Admin"
      display_name = "Admin"
      description  = "Admin role for the bjjeire-api. Grants write access to gym, event, and competition data."
    }
    tests_invoke = {
      id                   = "c2e5f8b4-3d6c-4f7d-9e8b-4c5d6e7f8091"
      value                = "Tests.Invoke"
      display_name         = "Tests.Invoke"
      description          = "Allows the bjjeire-tests app registration to call the API in CI and locally via the client-credentials flow. Granted only to the tests service principal."
      allowed_member_types = ["Application"]
    }
  }
  nullable = false

  validation {
    condition = alltrue([
      for role in values(var.api_app_roles) :
      length(trimspace(role.value)) > 0
      && length(trimspace(role.display_name)) > 0
      && length(trimspace(role.description)) > 0
      && length(role.allowed_member_types) > 0
      && alltrue([for member_type in role.allowed_member_types : contains(["User", "Application"], member_type)])
    ])
    error_message = "Each api_app_roles entry must have non-empty metadata and allowed_member_types containing only User and/or Application."
  }
}

variable "api_optional_claims" {
  type = object({
    access_token = optional(list(string), [])
    id_token     = optional(list(string), [])
    saml2_token  = optional(list(string), [])
  })
  description = "Optional claims emitted by the BjjEire API app registration."
  default = {
    access_token = ["groups"]
    id_token     = ["groups"]
  }
  nullable = false
}

variable "app_registration_group_membership_claims" {
  type        = set(string)
  description = "Group membership claims emitted by BjjEire app registrations."
  default     = ["SecurityGroup"]
  nullable    = false

  validation {
    condition = alltrue([
      for claim in var.app_registration_group_membership_claims :
      contains(["SecurityGroup", "ApplicationGroup", "DirectoryRole", "All", "None"], claim)
    ])
    error_message = "app_registration_group_membership_claims entries must be SecurityGroup, ApplicationGroup, DirectoryRole, All, or None."
  }
}

variable "spa_redirect_uris" {
  type        = list(string)
  description = "SPA redirect URIs registered on the bjjeire-spa app registration. Include the prod origin and any preview/test origins. Do NOT include localhost in prod tfvars."
  default     = ["https://bjjeire.com"]
  nullable    = false

  validation {
    condition = length(var.spa_redirect_uris) > 0 && alltrue([
      for uri in var.spa_redirect_uris :
      startswith(uri, "https://") || startswith(uri, "http://localhost") || startswith(uri, "http://127.0.0.1")
    ])
    error_message = "spa_redirect_uris must contain at least one HTTPS, http://localhost, or http://127.0.0.1 URI."
  }
}
