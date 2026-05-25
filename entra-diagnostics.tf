variable "entra_diagnostics_log_analytics_workspace_id" {
  type        = string
  description = "Resource ID of the Log Analytics workspace that receives Entra ID sign-in and audit logs. Pass empty string to disable export. Workspace lives outside this stack — usually in a central observability subscription."
  default     = ""
}

variable "entra_diagnostics_name_prefix" {
  type        = string
  default     = "entra-to-law-"
  description = "Prefix for the azurerm_monitor_aad_diagnostic_setting name. Final name: <prefix><environment>."
}

variable "entra_diagnostics_log_categories" {
  type = list(string)
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
  description = "Entra ID diagnostic log categories to forward. Drop entries to reduce ingestion cost — see Microsoft docs for the full catalogue."
}

resource "azurerm_monitor_aad_diagnostic_setting" "entra_to_law" {
  count = var.entra_diagnostics_log_analytics_workspace_id == "" ? 0 : 1

  name                       = "${var.entra_diagnostics_name_prefix}${var.environment}"
  log_analytics_workspace_id = var.entra_diagnostics_log_analytics_workspace_id

  dynamic "enabled_log" {
    for_each = toset(var.entra_diagnostics_log_categories)
    content {
      category = enabled_log.value
    }
  }
}
