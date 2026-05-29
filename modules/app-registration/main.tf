resource "azuread_application" "this" {
  display_name     = var.display_name
  sign_in_audience = var.sign_in_audience
  owners           = var.owners
  identifier_uris  = var.identifier_uris

  group_membership_claims = length(var.group_membership_claims) > 0 ? var.group_membership_claims : null

  dynamic "api" {
    for_each = (
      var.requested_access_token_version != null
      || length(var.oauth2_permission_scopes) > 0
    ) ? [1] : []

    content {
      requested_access_token_version = var.requested_access_token_version

      dynamic "oauth2_permission_scope" {
        for_each = var.oauth2_permission_scopes
        content {
          id                         = oauth2_permission_scope.value.id
          value                      = oauth2_permission_scope.value.value
          type                       = oauth2_permission_scope.value.type
          enabled                    = oauth2_permission_scope.value.enabled
          admin_consent_description  = oauth2_permission_scope.value.admin_consent_description
          admin_consent_display_name = oauth2_permission_scope.value.admin_consent_display_name
          user_consent_description   = oauth2_permission_scope.value.user_consent_description
          user_consent_display_name  = oauth2_permission_scope.value.user_consent_display_name
        }
      }
    }
  }

  dynamic "app_role" {
    for_each = var.app_roles
    content {
      id                   = app_role.value.id
      value                = app_role.value.value
      display_name         = app_role.value.display_name
      description          = app_role.value.description
      allowed_member_types = app_role.value.allowed_member_types
      enabled              = app_role.value.enabled
    }
  }

  dynamic "single_page_application" {
    for_each = length(var.spa_redirect_uris) > 0 ? [1] : []
    content {
      redirect_uris = var.spa_redirect_uris
    }
  }

  dynamic "web" {
    for_each = length(var.web_redirect_uris) > 0 ? [1] : []
    content {
      redirect_uris = var.web_redirect_uris
    }
  }

  dynamic "required_resource_access" {
    for_each = var.required_resource_access
    content {
      resource_app_id = required_resource_access.value.resource_app_id

      dynamic "resource_access" {
        for_each = required_resource_access.value.resource_access
        content {
          id   = resource_access.value.id
          type = resource_access.value.type
        }
      }
    }
  }

  dynamic "optional_claims" {
    for_each = (
      length(var.optional_claims.access_token) > 0
      || length(var.optional_claims.id_token) > 0
      || length(var.optional_claims.saml2_token) > 0
    ) ? [1] : []

    content {
      dynamic "access_token" {
        for_each = var.optional_claims.access_token
        content {
          name = access_token.value
        }
      }
      dynamic "id_token" {
        for_each = var.optional_claims.id_token
        content {
          name = id_token.value
        }
      }
      dynamic "saml2_token" {
        for_each = var.optional_claims.saml2_token
        content {
          name = saml2_token.value
        }
      }
    }
  }
}

resource "azuread_service_principal" "this" {
  client_id = azuread_application.this.client_id
  owners    = var.owners
}
