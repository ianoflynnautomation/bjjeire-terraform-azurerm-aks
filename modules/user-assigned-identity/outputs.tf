output "id" {
  description = "The ID of the user assigned identity."
  value       = azurerm_user_assigned_identity.this.id
}

output "principal_id" {
  description = "The Principal ID associated with this user assigned identity."
  value       = azurerm_user_assigned_identity.this.principal_id
}

output "client_id" {
  description = "The Client ID associated with this user assigned identity."
  value       = azurerm_user_assigned_identity.this.client_id
}

output "tenant_id" {
  description = "The Tenant ID associated with this user assigned identity."
  value       = azurerm_user_assigned_identity.this.tenant_id
}

output "name" {
  description = "The name of the user assigned identity."
  value       = azurerm_user_assigned_identity.this.name
}

output "resource" {
  description = "The user assigned identity resource."
  value       = azurerm_user_assigned_identity.this
}

output "federated_identity_credentials" {
  description = "A map of federated identity credentials created for this user assigned identity."
  value       = azurerm_federated_identity_credential.this
}

output "role_assignments" {
  description = "A map of role assignments created for this user assigned identity."
  value       = azurerm_role_assignment.this
}
