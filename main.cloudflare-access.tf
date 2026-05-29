# Cloudflare Zero Trust Access + Entra IdP composition.
#
# The previous main.cloudflare-idp.tf has been collapsed into the module
# below — IdP and Access live together because Access depends on the IdP.

locals {
  cloudflare_idp_enabled = var.enable_cloudflare_tunnel && local.cloudflare_account_id != ""
  cloudflare_access_enabled = (
    local.cloudflare_idp_enabled
    && var.cluster_domain != ""
    && var.cluster_domain != var.cloudflare_zone_name
  )
  cloudflare_access_app_name    = "${var.cloudflare_access_app_name_prefix}${var.environment}"
  cloudflare_access_policy_name = "${local.cloudflare_access_app_name}${var.cloudflare_access_policy_name_suffix}"
}

module "cloudflare_access_idp" {
  source = "./modules/cloudflare-access-idp"

  idp_enabled    = local.cloudflare_idp_enabled
  access_enabled = local.cloudflare_access_enabled
  account_id     = local.cloudflare_account_id
  tenant_id      = data.azurerm_client_config.current.tenant_id
  owners         = var.app_registration_owner_object_ids

  idp_app_name                        = "${var.cloudflare_idp_app_name_prefix}${var.environment}"
  idp_app_sign_in_audience            = var.cloudflare_idp_app_sign_in_audience
  idp_app_redirect_uri                = "https://${var.cloudflare_team_name}${var.cloudflare_auth_domain_suffix}${var.cloudflare_idp_callback_path}"
  idp_app_implicit_grant_access_token = var.cloudflare_idp_implicit_grant_access_token
  idp_app_implicit_grant_id_token     = var.cloudflare_idp_implicit_grant_id_token
  idp_app_group_membership_claims     = var.cloudflare_idp_group_membership_claims
  idp_app_id_token_claim_name         = var.cloudflare_idp_id_token_claim_name
  idp_app_access_token_claim_name     = var.cloudflare_idp_access_token_claim_name
  idp_app_password_display_name       = var.cloudflare_idp_password_display_name
  idp_app_delegated_permission_claims = var.cloudflare_idp_delegated_permission_claims

  cloudflare_idp_name           = format(var.cloudflare_idp_name_format, var.environment)
  cloudflare_idp_type           = var.cloudflare_idp_type
  cloudflare_idp_support_groups = var.cloudflare_idp_support_groups

  access_app_name                  = local.cloudflare_access_app_name
  access_app_type                  = var.cloudflare_access_app_type
  access_session_duration          = var.cloudflare_access_session_duration
  access_app_launcher_visible      = var.cloudflare_access_app_launcher_visible
  access_auto_redirect_to_identity = var.cloudflare_access_auto_redirect_to_identity
  access_destinations = [
    { type = var.cloudflare_access_destination_type, uri = var.cluster_domain },
    { type = var.cloudflare_access_destination_type, uri = "*.${var.cluster_domain}" },
  ]
  access_policy_name             = local.cloudflare_access_policy_name
  access_policy_decision         = var.cloudflare_access_policy_decision
  access_policy_precedence       = var.cloudflare_access_policy_precedence
  access_include_group_object_id = var.internal_access_group_object_id
  access_include_email_domain    = var.internal_access_email_domain
  access_include_emails          = var.internal_access_emails
}

# State migration. Chain the prior in-place rename (azure_ad -> entra_id)
# through into the module.
moved {
  from = cloudflare_zero_trust_access_identity_provider.azure_ad
  to   = cloudflare_zero_trust_access_identity_provider.entra_id
}

moved {
  from = cloudflare_zero_trust_access_identity_provider.entra_id
  to   = module.cloudflare_access_idp.cloudflare_zero_trust_access_identity_provider.entra_id
}

moved {
  from = azuread_application.cloudflare_idp
  to   = module.cloudflare_access_idp.azuread_application.this
}

moved {
  from = azuread_application_password.cloudflare_idp
  to   = module.cloudflare_access_idp.azuread_application_password.this
}

moved {
  from = azuread_service_principal.cloudflare_idp
  to   = module.cloudflare_access_idp.azuread_service_principal.this
}

moved {
  from = azuread_service_principal_delegated_permission_grant.cloudflare_idp
  to   = module.cloudflare_access_idp.azuread_service_principal_delegated_permission_grant.this
}

moved {
  from = cloudflare_zero_trust_access_application.cluster
  to   = module.cloudflare_access_idp.cloudflare_zero_trust_access_application.this
}

moved {
  from = cloudflare_zero_trust_access_policy.internal
  to   = module.cloudflare_access_idp.cloudflare_zero_trust_access_policy.internal
}
