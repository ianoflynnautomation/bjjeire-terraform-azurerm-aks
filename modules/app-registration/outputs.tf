output "id" {
  description = "Object ID of the application registration (used as application_id by azuread_application_pre_authorized)."
  value       = azuread_application.this.id
}

output "client_id" {
  description = "Client ID (appId) of the application registration. This is the 'app ID' shown in the portal."
  value       = azuread_application.this.client_id
}

output "service_principal_object_id" {
  description = "Object ID of the backing service principal. Use this for Azure RBAC role assignments, not the application object ID."
  value       = azuread_service_principal.this.object_id
}
