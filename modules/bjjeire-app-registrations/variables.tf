variable "api_audience_prefix" {
  type        = string
  default     = "api://"
  description = "Prefix used to build the API app's identifier_uri (audience). Final value: <prefix><api_display_name>."
}

variable "api_requested_access_token_version" {
  type        = number
  default     = 2
  description = "Access-token version requested on the API app registration. 2 = v2 tokens (JWT with the v2 issuer); 1 = legacy v1 tokens."
}

variable "environment" {
  type        = string
  description = "Environment suffix appended to app display names (e.g. \"prod\", \"dev\")."
  nullable    = false
}

variable "name_prefixes" {
  type = object({
    api = string
    spa = string
  })
  description = "Environment-agnostic display name prefixes for the API and SPA app registrations."
  nullable    = false

  validation {
    condition = (
      length(trimspace(var.name_prefixes.api)) > 0
      && length(trimspace(var.name_prefixes.spa)) > 0
    )
    error_message = "name_prefixes.api and .spa must be non-empty."
  }
}

variable "owners" {
  type        = list(string)
  description = "Entra ID object IDs of users or groups that own the API and SPA app registrations."
  default     = []
  nullable    = false
}

variable "microsoft_graph_resource_access" {
  type = object({
    app_id = string
    delegated_scopes = object({
      user_read = string
    })
  })
  description = "Microsoft Graph application ID and delegated permission IDs."
  nullable    = false
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
  description = "Delegated OAuth2 permission scopes exposed by the API app registration. Must include access_as_user."
  nullable    = false

  validation {
    condition     = contains(keys(var.api_oauth2_permission_scopes), "access_as_user")
    error_message = "api_oauth2_permission_scopes must include an access_as_user entry — the SPA pre-authorization wires it explicitly."
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
  description = "Application roles exposed by the API app registration."
  default     = {}
  nullable    = false
}

variable "api_optional_claims" {
  type = object({
    access_token = optional(list(string), [])
    id_token     = optional(list(string), [])
    saml2_token  = optional(list(string), [])
  })
  description = "Optional claims emitted by the API app registration."
  default     = {}
  nullable    = false
}

variable "group_membership_claims" {
  type        = set(string)
  description = "Group membership claims emitted by the API app registration."
  default     = ["SecurityGroup"]
  nullable    = false
}

variable "spa_redirect_uris" {
  type        = list(string)
  description = "SPA redirect URIs registered on the SPA app registration."
  default     = []
  nullable    = false
}
