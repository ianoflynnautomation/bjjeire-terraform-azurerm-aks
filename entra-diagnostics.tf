variable "entra_diagnostics_log_analytics_workspace_id" {
  type        = string
  description = "Resource ID of the Log Analytics workspace that receives Entra ID sign-in and audit logs. Pass empty string to disable export. Workspace lives outside this stack — usually in a central observability subscription."
  default     = ""
}

resource "azurerm_monitor_aad_diagnostic_setting" "entra_to_law" {
  count = var.entra_diagnostics_log_analytics_workspace_id == "" ? 0 : 1

  name                       = "entra-to-law-${var.environment}"
  log_analytics_workspace_id = var.entra_diagnostics_log_analytics_workspace_id

  enabled_log { category = "SignInLogs" }
  enabled_log { category = "AuditLogs" }
  enabled_log { category = "NonInteractiveUserSignInLogs" }
  enabled_log { category = "ServicePrincipalSignInLogs" }
  enabled_log { category = "ManagedIdentitySignInLogs" }
  enabled_log { category = "ADFSSignInLogs" }
  enabled_log { category = "RiskyUsers" }
  enabled_log { category = "UserRiskEvents" }
  enabled_log { category = "RiskyServicePrincipals" }
  enabled_log { category = "ServicePrincipalRiskEvents" }
  enabled_log { category = "ProvisioningLogs" }
}
