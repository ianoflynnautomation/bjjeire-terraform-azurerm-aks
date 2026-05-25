output "ids" {
  description = "Map of identity key => resource ID of the user-assigned identity."
  value       = { for k, m in module.identity : k => m.id }
}

output "client_ids" {
  description = "Map of identity key => client ID. Used for ServiceAccount annotations and CI secret values."
  value       = { for k, m in module.identity : k => m.client_id }
}

output "principal_ids" {
  description = "Map of identity key => principal (object) ID. Used for Azure RBAC role assignments."
  value       = { for k, m in module.identity : k => m.principal_id }
}

output "names" {
  description = "Map of identity key => Azure name of the identity."
  value       = { for k, m in module.identity : k => m.name }
}
