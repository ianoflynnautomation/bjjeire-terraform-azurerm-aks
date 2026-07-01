locals {
  api_display_name   = "${var.name_prefixes.api}-${var.environment}"
  spa_display_name   = "${var.name_prefixes.spa}-${var.environment}"
  tests_display_name = "${var.name_prefixes.tests}-${var.environment}"
  api_audience       = "${var.api_audience_prefix}${local.api_display_name}"

  # Entra required_resource_access types — fixed by the Graph permission API.
  resource_access_type_scope = "Scope"
  resource_access_type_role  = "Role"
}

module "api" {
  source = "../app-registration"

  display_name                   = local.api_display_name
  owners                         = var.owners
  identifier_uris                = [local.api_audience]
  requested_access_token_version = var.api_requested_access_token_version

  oauth2_permission_scopes = var.api_oauth2_permission_scopes
  app_roles                = var.api_app_roles

  required_resource_access = [
    {
      resource_app_id = var.microsoft_graph_resource_access.app_id
      resource_access = [
        { id = var.microsoft_graph_resource_access.delegated_scopes.user_read, type = local.resource_access_type_scope }
      ]
    }
  ]

  optional_claims         = var.api_optional_claims
  group_membership_claims = var.group_membership_claims
}

module "spa" {
  source = "../app-registration"

  display_name      = local.spa_display_name
  owners            = var.owners
  spa_redirect_uris = var.spa_redirect_uris

  required_resource_access = [
    {
      resource_app_id = module.api.client_id
      resource_access = [
        { id = var.api_oauth2_permission_scopes.access_as_user.id, type = local.resource_access_type_scope }
      ]
    },
    {
      resource_app_id = var.microsoft_graph_resource_access.app_id
      resource_access = [
        { id = var.microsoft_graph_resource_access.delegated_scopes.user_read, type = local.resource_access_type_scope }
      ]
    }
  ]
}

resource "azuread_application_pre_authorized" "spa_calls_api" {
  application_id       = module.api.id
  authorized_client_id = module.spa.client_id
  permission_ids       = [var.api_oauth2_permission_scopes.access_as_user.id]
}

module "tests" {
  source = "../app-registration"

  display_name = local.tests_display_name
  owners       = var.owners

  required_resource_access = [
    {
      resource_app_id = module.api.client_id
      resource_access = [
        { id = var.api_app_roles.tests_invoke.id, type = local.resource_access_type_role }
      ]
    }
  ]
}

resource "azuread_application_password" "tests" {
  application_id = module.tests.id
  display_name   = var.tests_password_display_name
}

# Grant the tests SP the Tests.Invoke app role on the API SP. The corresponding
# `roles` claim is emitted on client-credentials access tokens and validated by
# the Istio AuthorizationPolicy.
resource "azuread_app_role_assignment" "tests_invoke" {
  app_role_id         = var.api_app_roles.tests_invoke.id
  principal_object_id = module.tests.service_principal_object_id
  resource_object_id  = module.api.service_principal_object_id
}
