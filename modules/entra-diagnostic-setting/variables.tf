variable "name" {
  type        = string
  description = "Name of the Entra ID diagnostic setting."
  nullable    = false

  validation {
    condition     = length(trimspace(var.name)) > 0
    error_message = "name must be a non-empty string."
  }
}

variable "log_analytics_workspace_id" {
  type        = string
  description = "Resource ID of the Log Analytics workspace that receives Entra ID sign-in and audit logs. Empty string disables the module entirely (no resources created)."
  default     = ""
  nullable    = false
}

variable "log_categories" {
  type        = list(string)
  description = "Entra ID diagnostic log categories to forward. See Microsoft docs for the full catalogue."
  default = [
    "SignInLogs",
    "AuditLogs",
    "NonInteractiveUserSignInLogs",
    "ServicePrincipalSignInLogs",
    "ManagedIdentitySignInLogs",
    "ADFSSignInLogs",
    "RiskyUsers",
    "UserRiskEvents",
    "RiskyServicePrincipals",
    "ServicePrincipalRiskEvents",
    "ProvisioningLogs",
  ]
  nullable = false

  validation {
    condition     = length(var.log_categories) > 0
    error_message = "log_categories must contain at least one category."
  }
}
