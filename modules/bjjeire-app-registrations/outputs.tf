output "api_client_id" {
  description = "Client ID of the API app registration."
  value       = module.api.client_id
}

output "api_application_object_id" {
  description = "Object ID of the API app registration (azuread_application.id)."
  value       = module.api.id
}

output "spa_client_id" {
  description = "Client ID of the SPA app registration."
  value       = module.spa.client_id
}

output "api_audience" {
  description = "Application ID URI of the API (api://<display-name>)."
  value       = local.api_audience
}
