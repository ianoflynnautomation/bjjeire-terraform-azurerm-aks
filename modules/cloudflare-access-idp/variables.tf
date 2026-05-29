variable "idp_enabled" {
  type        = bool
  description = "When false, neither the Entra IdP-side resources nor the Cloudflare IdP are created."
  default     = true
  nullable    = false
}

variable "access_enabled" {
  type        = bool
  description = "When false, the Cloudflare Access app + policy are not created. Caller should also set idp_enabled=false unless the IdP is wanted standalone."
  default     = true
  nullable    = false
}

variable "account_id" {
  type        = string
  description = "Cloudflare account ID. Must be non-empty when idp_enabled = true."
  nullable    = false
}

variable "tenant_id" {
  type        = string
  description = "Entra ID tenant ID used as the Cloudflare IdP directory_id."
  nullable    = false
}

variable "owners" {
  type        = list(string)
  description = "Entra ID object IDs that own the IdP app registration + service principal."
  nullable    = false
}

# ----- Entra app registration -----

variable "idp_app_name" {
  type        = string
  description = "Display name of the Entra app registration used by Cloudflare for OIDC."
  nullable    = false
}

variable "idp_app_sign_in_audience" {
  type        = string
  description = "sign_in_audience for the Entra app."
  default     = "AzureADMyOrg"
  nullable    = false
}

variable "idp_app_redirect_uri" {
  type        = string
  description = "Cloudflare Access OIDC callback URL (caller pre-composes from team_name + auth_domain_suffix + callback_path)."
  nullable    = false
}

variable "idp_app_implicit_grant_access_token" {
  type        = bool
  description = "Allow implicit grant access tokens on the Entra app. Stay false for OIDC code flow."
  default     = false
  nullable    = false
}

variable "idp_app_implicit_grant_id_token" {
  type        = bool
  description = "Allow implicit grant id tokens on the Entra app. Stay false for OIDC code flow."
  default     = false
  nullable    = false
}

variable "idp_app_group_membership_claims" {
  type        = list(string)
  description = "group_membership_claims restricting which group kinds appear in the groups claim."
  default     = ["SecurityGroup"]
  nullable    = false
}

variable "idp_app_id_token_claim_name" {
  type        = string
  description = "optional_claims.id_token name added on the Entra app."
  default     = "groups"
  nullable    = false
}

variable "idp_app_access_token_claim_name" {
  type        = string
  description = "optional_claims.access_token name added on the Entra app."
  default     = "groups"
  nullable    = false
}

variable "idp_app_password_display_name" {
  type        = string
  description = "display_name of the application password used as the IdP client secret."
  default     = "cloudflare-zero-trust"
  nullable    = false
}

variable "idp_app_delegated_permission_claims" {
  type        = list(string)
  description = "Delegated Microsoft Graph permission claim values pre-consented for the Cloudflare IdP."
  default     = ["User.Read", "GroupMember.Read.All"]
  nullable    = false
}

# ----- Cloudflare IdP -----

variable "cloudflare_idp_name" {
  type        = string
  description = "Display name of the Cloudflare Zero Trust IdP (caller pre-composes any format)."
  nullable    = false
}

variable "cloudflare_idp_type" {
  type        = string
  description = "Cloudflare Zero Trust IdP type — Cloudflare API enum (e.g. azureAD for Entra ID)."
  default     = "azureAD"
  nullable    = false
}

variable "cloudflare_idp_support_groups" {
  type        = bool
  description = "Tell Cloudflare to fetch group claims from the IdP."
  default     = true
  nullable    = false
}

# ----- Cloudflare Access app + policy -----

variable "access_app_name" {
  type        = string
  description = "Cloudflare Zero Trust Access application name."
  nullable    = false
}

variable "access_app_type" {
  type        = string
  description = "Access application type (self_hosted, saas, ssh, vnc)."
  default     = "self_hosted"
  nullable    = false
}

variable "access_session_duration" {
  type        = string
  description = "Access session lifetime (Go duration)."
  default     = "8h"
  nullable    = false
}

variable "access_app_launcher_visible" {
  type        = bool
  description = "Show the app in the Cloudflare Access launcher tile UI."
  default     = true
  nullable    = false
}

variable "access_auto_redirect_to_identity" {
  type        = bool
  description = "Skip the Cloudflare login chooser and redirect straight to the configured IdP."
  default     = true
  nullable    = false
}

variable "access_destinations" {
  type = list(object({
    type = string
    uri  = string
  }))
  description = "Destinations the Access app gates (typically [{type=public, uri=cluster_domain}, {type=public, uri=*.cluster_domain}])."
  nullable    = false

  validation {
    condition     = length(var.access_destinations) > 0
    error_message = "access_destinations must contain at least one entry."
  }
}

variable "access_policy_name" {
  type        = string
  description = "Name of the Access policy attached to the app."
  nullable    = false
}

variable "access_policy_decision" {
  type        = string
  description = "Access policy decision."
  default     = "allow"
  nullable    = false

  validation {
    condition     = contains(["allow", "block", "non_identity", "bypass"], var.access_policy_decision)
    error_message = "access_policy_decision must be one of: allow, block, non_identity, bypass."
  }
}

variable "access_policy_precedence" {
  type        = number
  description = "Precedence (rank) of the Access policy under the app. Lower = evaluated first."
  default     = 1
  nullable    = false
}

variable "access_include_group_object_id" {
  type        = string
  description = "Entra group object ID added as an Access allow rule. Empty string omits this include type."
  default     = ""
  nullable    = false
}

variable "access_include_email_domain" {
  type        = string
  description = "Email domain accepted as an Access allow rule. Empty string omits this include type."
  default     = ""
  nullable    = false
}

variable "access_include_emails" {
  type        = list(string)
  description = "Specific email addresses accepted as Access allow rules. Empty list omits this include type."
  default     = []
  nullable    = false
}
