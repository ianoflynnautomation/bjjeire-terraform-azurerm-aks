output "id" {
  description = "Resource ID of the diagnostic setting. Null when disabled."
  value       = try(azurerm_monitor_aad_diagnostic_setting.this[0].id, null)
}

output "name" {
  description = "Name of the diagnostic setting. Null when disabled."
  value       = try(azurerm_monitor_aad_diagnostic_setting.this[0].name, null)
}
