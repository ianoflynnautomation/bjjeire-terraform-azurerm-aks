output "id" {
  description = "Resource ID of the budget. Null when amount <= 0."
  value       = try(azurerm_consumption_budget_resource_group.this[0].id, null)
}

output "name" {
  description = "Name of the budget. Null when amount <= 0."
  value       = try(azurerm_consumption_budget_resource_group.this[0].name, null)
}
