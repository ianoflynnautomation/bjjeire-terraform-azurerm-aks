# Cloudflare Zero Trust identity provider — Entra ID (Azure AD).
#
# Creates the Entra App Registration that Cloudflare uses to OIDC-auth users,
# then registers it as a Cloudflare Zero Trust identity provider. The IdP ID
# is consumed by cloudflare-access.tf to gate self-hosted apps.
#
# Group claims: enabling support_groups = true lets the Access policy match on
# Entra group Object IDs (var.internal_access_group_object_id). Make sure the
# group is a Security group with members assigned in Entra ID.

locals {
  cloudflare_idp_enabled = var.enable_cloudflare_tunnel && local.cloudflare_account_id != ""

  msgraph_app_id                      = "00000003-0000-0000-c000-000000000000"
  msgraph_scope_user_read             = "e1fe6dd8-ba31-4d61-89e7-88639da4683d"
  msgraph_scope_group_member_read_all = "bc024368-1153-4739-b217-4326f2e966d0"
  msgraph_resource_access_type_scope  = "Scope"
}

resource "azuread_application" "cloudflare_idp" {
  count = local.cloudflare_idp_enabled ? 1 : 0

  display_name     = "${var.cloudflare_idp_app_name_prefix}${var.environment}"
  sign_in_audience = var.cloudflare_idp_app_sign_in_audience
  owners           = var.app_registration_owner_object_ids

  web {
    # Cloudflare callback URL — see Zero Trust IdP setup docs.
    redirect_uris = ["https://${local.cloudflare_team_name}${var.cloudflare_auth_domain_suffix}${var.cloudflare_idp_callback_path}"]
    implicit_grant {
      access_token_issuance_enabled = var.cloudflare_idp_implicit_grant_access_token
      id_token_issuance_enabled     = var.cloudflare_idp_implicit_grant_id_token
    }
  }

  required_resource_access {
    resource_app_id = local.msgraph_app_id

    resource_access {
      # User.Read (delegated)
      id   = local.msgraph_scope_user_read
      type = local.msgraph_resource_access_type_scope
    }
    resource_access {
      # GroupMember.Read.All (delegated) — needed for group-based Access policies
      id   = local.msgraph_scope_group_member_read_all
      type = local.msgraph_resource_access_type_scope
    }
  }

  group_membership_claims = var.cloudflare_idp_group_membership_claims
  optional_claims {
    id_token {
      name = var.cloudflare_idp_id_token_claim_name
    }
    access_token {
      name = var.cloudflare_idp_access_token_claim_name
    }
  }
}

resource "azuread_application_password" "cloudflare_idp" {
  count = local.cloudflare_idp_enabled ? 1 : 0

  application_id = azuread_application.cloudflare_idp[0].id
  display_name   = var.cloudflare_idp_password_display_name
}

resource "azuread_service_principal" "cloudflare_idp" {
  count = local.cloudflare_idp_enabled ? 1 : 0

  client_id = azuread_application.cloudflare_idp[0].client_id
  owners    = var.app_registration_owner_object_ids
}

data "azuread_service_principal" "msgraph" {
  count     = local.cloudflare_idp_enabled ? 1 : 0
  client_id = local.msgraph_app_id
}

# Tenant-wide admin consent for the delegated Graph scopes Cloudflare needs.
# Requires the Terraform principal to hold Global Administrator or Privileged
# Role Administrator at apply time. Once granted, end users no longer see the
# consent prompt on first Cloudflare Access sign-in.
resource "azuread_service_principal_delegated_permission_grant" "cloudflare_idp" {
  count = local.cloudflare_idp_enabled ? 1 : 0

  service_principal_object_id          = azuread_service_principal.cloudflare_idp[0].object_id
  resource_service_principal_object_id = data.azuread_service_principal.msgraph[0].object_id
  claim_values                         = var.cloudflare_idp_delegated_permission_claims
}

resource "cloudflare_zero_trust_access_identity_provider" "entra_id" {
  count = local.cloudflare_idp_enabled ? 1 : 0

  account_id = local.cloudflare_account_id
  name       = format(var.cloudflare_idp_name_format, var.environment)
  type       = var.cloudflare_idp_type

  config = {
    client_id      = azuread_application.cloudflare_idp[0].client_id
    client_secret  = azuread_application_password.cloudflare_idp[0].value
    directory_id   = data.azurerm_client_config.current.tenant_id
    support_groups = var.cloudflare_idp_support_groups
  }
}

moved {
  from = cloudflare_zero_trust_access_identity_provider.azure_ad
  to   = cloudflare_zero_trust_access_identity_provider.entra_id
}
