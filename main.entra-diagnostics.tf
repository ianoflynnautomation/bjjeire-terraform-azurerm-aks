variable "entra_diagnostics_log_analytics_workspace_id" {
  type        = string
  description = "Resource ID of the Log Analytics workspace that receives Entra ID sign-in and audit logs. Pass empty string to disable export. Workspace lives outside this stack — usually in a central observability subscription."
  default     = ""
}

variable "entra_diagnostics_name_prefix" {
  type        = string
  default     = "entra-to-law-"
  description = "Prefix for the diagnostic setting name. Final name: <prefix><environment>."
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

module "entra_diagnostic_setting" {
  source = "./modules/entra-diagnostic-setting"

  name                       = "${var.entra_diagnostics_name_prefix}${var.environment}"
  log_analytics_workspace_id = var.entra_diagnostics_log_analytics_workspace_id
  log_categories             = var.entra_diagnostics_log_categories
}

moved {
  from = azurerm_monitor_aad_diagnostic_setting.entra_to_law
  to   = module.entra_diagnostic_setting.azurerm_monitor_aad_diagnostic_setting.this
}
