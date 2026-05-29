resource "azurerm_monitor_aad_diagnostic_setting" "this" {
  count = var.log_analytics_workspace_id == "" ? 0 : 1

  name                       = var.name
  log_analytics_workspace_id = var.log_analytics_workspace_id

  dynamic "enabled_log" {
    for_each = toset(var.log_categories)
    content {
      category = enabled_log.value
    }
  }
}
