output "api_client_id" {
  description = "Client ID of the API app registration."
  value       = module.api.client_id
}

output "api_application_object_id" {
  description = "Object ID of the API app registration (azuread_application.id)."
  value       = module.api.id
}

output "api_service_principal_object_id" {
  description = "Object ID of the API service principal. Use as resource_object_id when assigning app roles to other principals (UAMIs, SPs) via azuread_app_role_assignment."
  value       = module.api.service_principal_object_id
}

output "spa_client_id" {
  description = "Client ID of the SPA app registration."
  value       = module.spa.client_id
}

output "api_audience" {
  description = "Application ID URI of the API (api://<display-name>)."
  value       = local.api_audience
}

output "tests_client_id" {
  description = "Client ID of the tests app registration. Consumed by CI/local tests as AZURE_CLIENT_ID."
  value       = module.tests.client_id
}

output "tests_client_secret" {
  description = "Client secret on the tests app registration. Consumed by CI/local tests as AZURE_CLIENT_SECRET. Sensitive."
  value       = azuread_application_password.tests.value
  sensitive   = true
}
