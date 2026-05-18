locals {
  bjjeire_app_registrations = {
    api = {
      display_name = "${var.bjjeire_app_registration_name_prefixes.api}-${var.environment}"
      audience     = "api://${var.bjjeire_app_registration_name_prefixes.api}-${var.environment}"
    }

    spa = {
      display_name = "${var.bjjeire_app_registration_name_prefixes.spa}-${var.environment}"
    }
  }

  bjjeire_api_audience = local.bjjeire_app_registrations.api.audience
}

module "app_reg_api" {
  source = "./modules/app-registration"

  display_name                   = local.bjjeire_app_registrations.api.display_name
  owners                         = var.app_registration_owner_object_ids
  identifier_uris                = [local.bjjeire_api_audience]
  requested_access_token_version = 2

  oauth2_permission_scopes = var.bjjeire_api_oauth2_permission_scopes
  app_roles                = var.bjjeire_api_app_roles

  required_resource_access = [
    {
      resource_app_id = var.microsoft_graph_resource_access.app_id
      resource_access = [
        { id = var.microsoft_graph_resource_access.delegated_scopes.user_read, type = "Scope" }
      ]
    }
  ]

  optional_claims = var.bjjeire_api_optional_claims

  group_membership_claims = var.bjjeire_app_registration_group_membership_claims
}

module "app_reg_spa" {
  source = "./modules/app-registration"

  display_name      = local.bjjeire_app_registrations.spa.display_name
  owners            = var.app_registration_owner_object_ids
  spa_redirect_uris = var.bjjeire_spa_redirect_uris

  required_resource_access = [
    {
      resource_app_id = module.app_reg_api.client_id
      resource_access = [
        { id = var.bjjeire_api_oauth2_permission_scopes.access_as_user.id, type = "Scope" }
      ]
    },
    {
      resource_app_id = var.microsoft_graph_resource_access.app_id
      resource_access = [
        { id = var.microsoft_graph_resource_access.delegated_scopes.user_read, type = "Scope" }
      ]
    }
  ]
}

resource "azuread_application_pre_authorized" "spa_calls_api" {
  application_id       = module.app_reg_api.id
  authorized_client_id = module.app_reg_spa.client_id
  permission_ids       = [var.bjjeire_api_oauth2_permission_scopes.access_as_user.id]
}

output "bjjeire_api_client_id" {
  description = "Client ID of the bjjeire-api app registration. Used by the API JWT validation and the SPA's MSAL_API_SCOPE."
  value       = module.app_reg_api.client_id
}

output "bjjeire_spa_client_id" {
  description = "Client ID of the bjjeire-spa app registration. Used as VITE_APP_MSAL_CLIENT_ID."
  value       = module.app_reg_spa.client_id
}

output "bjjeire_api_audience" {
  description = "Application ID URI of the bjjeire-api. Used as VITE_APP_MSAL_API_SCOPE (with /access_as_user appended) and as the API's AzureAd__Audience."
  value       = local.bjjeire_api_audience
}

output "bjjeire_spa_msal_tenant_id" {
  description = "Tenant ID for the SPA's MSAL config. Used as VITE_APP_MSAL_TENANT_ID; the SPA composes the authority URL in code."
  value       = data.azurerm_client_config.current.tenant_id
}
