locals {
  # Well-known Microsoft Graph IDs — fixed by the protocol.
  msgraph_app_id                      = "00000003-0000-0000-c000-000000000000"
  msgraph_scope_user_read             = "e1fe6dd8-ba31-4d61-89e7-88639da4683d"
  msgraph_scope_group_member_read_all = "bc024368-1153-4739-b217-4326f2e966d0"
  msgraph_resource_access_type_scope  = "Scope"

  has_access_include_rule = (
    var.access_include_group_object_id != "" ||
    var.access_include_email_domain != "" ||
    length(var.access_include_emails) > 0
  )

  create_access              = var.access_enabled && var.idp_enabled && local.has_access_include_rule
  create_tests_service_token = local.create_access && trimspace(var.tests_service_token_name) != ""
}

# ----- Entra app registration + secret + SPN + delegated grant -----

resource "azuread_application" "this" {
  count = var.idp_enabled ? 1 : 0

  display_name     = var.idp_app_name
  sign_in_audience = var.idp_app_sign_in_audience
  owners           = var.owners

  web {
    redirect_uris = [var.idp_app_redirect_uri]
    implicit_grant {
      access_token_issuance_enabled = var.idp_app_implicit_grant_access_token
      id_token_issuance_enabled     = var.idp_app_implicit_grant_id_token
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
      # GroupMember.Read.All (delegated)
      id   = local.msgraph_scope_group_member_read_all
      type = local.msgraph_resource_access_type_scope
    }
  }

  group_membership_claims = var.idp_app_group_membership_claims
  optional_claims {
    id_token {
      name = var.idp_app_id_token_claim_name
    }
    access_token {
      name = var.idp_app_access_token_claim_name
    }
  }
}

resource "azuread_application_password" "this" {
  count = var.idp_enabled ? 1 : 0

  application_id = azuread_application.this[0].id
  display_name   = var.idp_app_password_display_name
}

resource "azuread_service_principal" "this" {
  count = var.idp_enabled ? 1 : 0

  client_id = azuread_application.this[0].client_id
  owners    = var.owners
}

data "azuread_service_principal" "msgraph" {
  count     = var.idp_enabled ? 1 : 0
  client_id = local.msgraph_app_id
}

# Tenant-wide admin consent for the delegated Graph scopes Cloudflare needs.
# Requires the Terraform principal to hold Global Administrator or Privileged
# Role Administrator at apply time.
resource "azuread_service_principal_delegated_permission_grant" "this" {
  count = var.idp_enabled ? 1 : 0

  service_principal_object_id          = azuread_service_principal.this[0].object_id
  resource_service_principal_object_id = data.azuread_service_principal.msgraph[0].object_id
  claim_values                         = var.idp_app_delegated_permission_claims
}

# ----- Cloudflare IdP -----

resource "cloudflare_zero_trust_access_identity_provider" "entra_id" {
  count = var.idp_enabled ? 1 : 0

  account_id = var.account_id
  name       = var.cloudflare_idp_name
  type       = var.cloudflare_idp_type

  config = {
    client_id      = azuread_application.this[0].client_id
    client_secret  = azuread_application_password.this[0].value
    directory_id   = var.tenant_id
    support_groups = var.cloudflare_idp_support_groups
  }
}

# ----- Cloudflare Access app + policy -----

resource "cloudflare_zero_trust_access_application" "this" {
  count = local.create_access ? 1 : 0

  account_id                = var.account_id
  name                      = var.access_app_name
  type                      = var.access_app_type
  session_duration          = var.access_session_duration
  app_launcher_visible      = var.access_app_launcher_visible
  auto_redirect_to_identity = var.access_auto_redirect_to_identity
  allowed_idps              = [cloudflare_zero_trust_access_identity_provider.entra_id[0].id]

  destinations = var.access_destinations

  policies = concat(
    [{
      id         = cloudflare_zero_trust_access_policy.internal[0].id
      precedence = var.access_policy_precedence
    }],
    local.create_tests_service_token ? [{
      id         = cloudflare_zero_trust_access_policy.tests_service_token[0].id
      precedence = var.tests_service_token_policy_precedence
    }] : [],
  )
}

resource "cloudflare_zero_trust_access_policy" "internal" {
  count = local.create_access ? 1 : 0

  account_id = var.account_id
  name       = var.access_policy_name
  decision   = var.access_policy_decision

  include = concat(
    var.access_include_group_object_id != "" ? [{
      azure_ad = {
        identity_provider_id = cloudflare_zero_trust_access_identity_provider.entra_id[0].id
        id                   = var.access_include_group_object_id
      }
    }] : [],
    var.access_include_email_domain != "" ? [{
      email_domain = { domain = var.access_include_email_domain }
    }] : [],
    length(var.access_include_emails) > 0 ? [
      for e in var.access_include_emails : { email = { email = e } }
    ] : [],
  )
}

resource "cloudflare_zero_trust_access_service_token" "tests" {
  count = local.create_tests_service_token ? 1 : 0

  account_id = var.account_id
  name       = var.tests_service_token_name
}

resource "cloudflare_zero_trust_access_policy" "tests_service_token" {
  count = local.create_tests_service_token ? 1 : 0

  account_id = var.account_id
  name       = var.tests_service_token_policy_name
  decision   = "non_identity"

  include = [{
    service_token = {
      token_id = cloudflare_zero_trust_access_service_token.tests[0].id
    }
  }]
}
