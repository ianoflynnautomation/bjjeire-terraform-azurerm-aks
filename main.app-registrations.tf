module "bjjeire_app_registrations" {
  source = "./modules/bjjeire-app-registrations"

  environment   = var.environment
  name_prefixes = var.app_registration_name_prefixes
  owners        = var.app_registration_owner_object_ids

  microsoft_graph_resource_access = var.microsoft_graph_resource_access

  api_oauth2_permission_scopes = var.api_oauth2_permission_scopes
  api_app_roles                = var.api_app_roles
  api_optional_claims          = var.api_optional_claims

  group_membership_claims = var.app_registration_group_membership_claims
  spa_redirect_uris       = var.spa_redirect_uris
}

moved {
  from = module.app_reg_api
  to   = module.bjjeire_app_registrations.module.api
}

moved {
  from = module.app_reg_spa
  to   = module.bjjeire_app_registrations.module.spa
}

moved {
  from = azuread_application_pre_authorized.spa_calls_api
  to   = module.bjjeire_app_registrations.azuread_application_pre_authorized.spa_calls_api
}

output "bjjeire_api_client_id" {
  description = "Client ID of the bjjeire-api app registration. Used by the API JWT validation and the SPA's MSAL_API_SCOPE."
  value       = module.bjjeire_app_registrations.api_client_id
}

output "bjjeire_spa_client_id" {
  description = "Client ID of the bjjeire-spa app registration. Used as VITE_APP_MSAL_CLIENT_ID."
  value       = module.bjjeire_app_registrations.spa_client_id
}

output "bjjeire_api_audience" {
  description = "Application ID URI of the bjjeire-api. Used as VITE_APP_MSAL_API_SCOPE (with /access_as_user appended) and as the API's AzureAd__Audience."
  value       = module.bjjeire_app_registrations.api_audience
}

output "bjjeire_spa_msal_tenant_id" {
  description = "Tenant ID for the SPA's MSAL config. Used as VITE_APP_MSAL_TENANT_ID; the SPA composes the authority URL in code."
  value       = data.azurerm_client_config.current.tenant_id
}

output "bjjeire_tests_client_id" {
  description = "Client ID of the bjjeire-tests app registration. Consumed by CI/local tests as AZURE_CLIENT_ID for the client-credentials flow."
  value       = module.bjjeire_app_registrations.tests_client_id
}

output "bjjeire_tests_client_secret" {
  description = "Client secret of the bjjeire-tests app registration. Consumed by CI/local tests as AZURE_CLIENT_SECRET. Stored in Key Vault — do not print to logs."
  value       = module.bjjeire_app_registrations.tests_client_secret
  sensitive   = true
}
