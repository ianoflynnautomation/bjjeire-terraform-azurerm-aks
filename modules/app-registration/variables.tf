variable "display_name" {
  type        = string
  description = "Display name of the application registration."
  nullable    = false

  validation {
    condition     = length(trimspace(var.display_name)) > 0 && length(var.display_name) <= 120
    error_message = "display_name must be non-empty and no longer than 120 characters."
  }
}

variable "sign_in_audience" {
  type        = string
  description = "Sign-in audience: AzureADMyOrg (single-tenant), AzureADMultipleOrgs, AzureADandPersonalMicrosoftAccount, PersonalMicrosoftAccount."
  default     = "AzureADMyOrg"
  nullable    = false

  validation {
    condition     = contains(["AzureADMyOrg", "AzureADMultipleOrgs", "AzureADandPersonalMicrosoftAccount", "PersonalMicrosoftAccount"], var.sign_in_audience)
    error_message = "sign_in_audience must be one of: AzureADMyOrg, AzureADMultipleOrgs, AzureADandPersonalMicrosoftAccount, PersonalMicrosoftAccount."
  }
}

variable "owners" {
  type        = list(string)
  description = "Entra ID object IDs of users or groups that own the application registration. At least two human owners is recommended."
  default     = []
  nullable    = false
}

variable "identifier_uris" {
  type        = list(string)
  description = "Application ID URIs the app is identified by (the 'aud' claim API tokens carry). Required for API apps; leave empty for SPAs and OAuth clients."
  default     = []
  nullable    = false

  validation {
    condition = alltrue([
      for uri in var.identifier_uris :
      startswith(uri, "api://") || startswith(uri, "https://")
    ])
    error_message = "identifier_uris must start with api:// or https://."
  }
}

variable "requested_access_token_version" {
  type        = number
  description = "Access token version. 2 = standard OIDC v2.0 tokens (required for Microsoft.Identity.Web defaults); 1 = legacy AAD v1.0. Set to null for SPAs that don't expose an API."
  default     = null

  validation {
    condition     = var.requested_access_token_version == null ? true : contains([1, 2], var.requested_access_token_version)
    error_message = "requested_access_token_version must be 1 or 2."
  }
}

variable "oauth2_permission_scopes" {
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
  description = <<-EOT
  Delegated OAuth2 permission scopes the app exposes. Map key is arbitrary; `id` is a stable GUID that must NOT change once consented.

  - `id` - Stable GUID for the scope. Generate once with uuidgen and never change.
  - `value` - The scope name appended to the audience (e.g. `access_as_user` → `api://app/access_as_user`).
  - `type` - "User" (user-consentable) or "Admin" (admin-only consent).
  EOT
  default     = {}
  nullable    = false

  validation {
    condition = alltrue([
      for scope in values(var.oauth2_permission_scopes) :
      contains(["User", "Admin"], scope.type)
      && length(trimspace(scope.value)) > 0
      && length(trimspace(scope.admin_consent_description)) > 0
      && length(trimspace(scope.admin_consent_display_name)) > 0
    ])
    error_message = "Each oauth2_permission_scopes entry must use type User or Admin and non-empty consent metadata."
  }
}

variable "app_roles" {
  type = map(object({
    id                   = string
    value                = string
    display_name         = string
    description          = string
    allowed_member_types = optional(list(string), ["User"])
    enabled              = optional(bool, true)
  }))
  description = <<-EOT
  Application roles the app exposes. Map key is arbitrary; `id` is a stable GUID that must NOT change once assigned.

  - `id` - Stable GUID for the role. Generate once and never change.
  - `value` - String that appears in the `roles` claim (e.g. "Admin").
  - `allowed_member_types` - "User" (assigned to users/groups), "Application" (assigned to other apps for daemon-style access), or both.
  EOT
  default     = {}
  nullable    = false

  validation {
    condition = alltrue([
      for role in values(var.app_roles) :
      length(trimspace(role.value)) > 0
      && length(trimspace(role.display_name)) > 0
      && length(trimspace(role.description)) > 0
      && length(role.allowed_member_types) > 0
      && alltrue([for member_type in role.allowed_member_types : contains(["User", "Application"], member_type)])
    ])
    error_message = "Each app_roles entry must have non-empty metadata and allowed_member_types containing only User and/or Application."
  }
}

variable "spa_redirect_uris" {
  type        = list(string)
  description = "Single-page-application redirect URIs (Auth Code + PKCE). Use this for browser apps like React MSAL.js. Mutually exclusive with web_redirect_uris."
  default     = []
  nullable    = false

  validation {
    condition = alltrue([
      for uri in var.spa_redirect_uris :
      startswith(uri, "https://") || startswith(uri, "http://localhost") || startswith(uri, "http://127.0.0.1")
    ])
    error_message = "spa_redirect_uris must be HTTPS, http://localhost, or http://127.0.0.1 URIs."
  }

  validation {
    condition     = length(var.spa_redirect_uris) == 0 || length(var.web_redirect_uris) == 0
    error_message = "spa_redirect_uris and web_redirect_uris are mutually exclusive."
  }
}

variable "web_redirect_uris" {
  type        = list(string)
  description = "Confidential web client redirect URIs (Auth Code with client secret/certificate). Use this for server-side apps like oauth2-proxy. Mutually exclusive with spa_redirect_uris."
  default     = []
  nullable    = false

  validation {
    condition = alltrue([
      for uri in var.web_redirect_uris :
      startswith(uri, "https://")
    ])
    error_message = "web_redirect_uris must be HTTPS URIs."
  }
}

variable "required_resource_access" {
  type = list(object({
    resource_app_id = string
    resource_access = list(object({
      id   = string
      type = string
    }))
  }))
  description = <<-EOT
  APIs this app calls. Each entry pairs a target resource (by client ID) with a list of permission GUIDs.

  - `resource_app_id` - Client ID of the resource (e.g. Microsoft Graph = "00000003-0000-0000-c000-000000000000", or another app reg's client_id).
  - `resource_access[].id` - GUID of the permission (delegated scope ID or app role ID on the target).
  - `resource_access[].type` - "Scope" (delegated) or "Role" (application).
  EOT
  default     = []
  nullable    = false

  validation {
    condition = alltrue(flatten([
      for access in var.required_resource_access : [
        alltrue([
          for resource_access in access.resource_access :
          contains(["Scope", "Role"], resource_access.type)
        ])
      ]
    ]))
    error_message = "required_resource_access resource_access.type must be Scope or Role."
  }
}

variable "optional_claims" {
  type = object({
    access_token = optional(list(string), [])
    id_token     = optional(list(string), [])
    saml2_token  = optional(list(string), [])
  })
  description = "Optional claim names to include in each token type (e.g. [\"groups\"] to embed group object IDs)."
  default     = {}
  nullable    = false

  validation {
    condition = alltrue(concat(
      [for claim in var.optional_claims.access_token : length(trimspace(claim)) > 0],
      [for claim in var.optional_claims.id_token : length(trimspace(claim)) > 0],
      [for claim in var.optional_claims.saml2_token : length(trimspace(claim)) > 0]
    ))
    error_message = "optional_claims entries must be non-empty claim names."
  }
}

variable "group_membership_claims" {
  type        = set(string)
  description = "Which group memberships are emitted in the `groups` claim. Allowed values: SecurityGroup, ApplicationGroup, DirectoryRole, All, None. Empty set omits the claim."
  default     = []
  nullable    = false

  validation {
    condition = alltrue([
      for c in var.group_membership_claims :
      contains(["SecurityGroup", "ApplicationGroup", "DirectoryRole", "All", "None"], c)
    ]) && (!contains(var.group_membership_claims, "None") || length(var.group_membership_claims) == 1)
    error_message = "Each group_membership_claims entry must be one of: SecurityGroup, ApplicationGroup, DirectoryRole, All, None. None cannot be combined with other values."
  }
}
