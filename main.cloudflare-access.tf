locals {
  has_access_include_rule = (
    var.internal_access_group_object_id != "" ||
    var.internal_access_email_domain != "" ||
    length(var.internal_access_emails) > 0
  )
  cloudflare_access_enabled = (
    local.cloudflare_idp_enabled &&
    var.cluster_domain != "" &&
    var.cluster_domain != var.cloudflare_zone_name &&
    local.has_access_include_rule
  )
  cloudflare_idp_id = local.cloudflare_idp_enabled ? cloudflare_zero_trust_access_identity_provider.entra_id[0].id : ""

  cloudflare_access_app_name    = "${var.cloudflare_access_app_name_prefix}${var.environment}"
  cloudflare_access_policy_name = "${local.cloudflare_access_app_name}${var.cloudflare_access_policy_name_suffix}"
}

resource "cloudflare_zero_trust_access_application" "cluster" {
  count = local.cloudflare_access_enabled ? 1 : 0

  account_id                = local.cloudflare_account_id
  name                      = local.cloudflare_access_app_name
  type                      = var.cloudflare_access_app_type
  session_duration          = var.cloudflare_access_session_duration
  app_launcher_visible      = var.cloudflare_access_app_launcher_visible
  auto_redirect_to_identity = var.cloudflare_access_auto_redirect_to_identity
  allowed_idps              = [local.cloudflare_idp_id]

  destinations = [
    { type = var.cloudflare_access_destination_type, uri = var.cluster_domain },
    { type = var.cloudflare_access_destination_type, uri = "*.${var.cluster_domain}" },
  ]

  policies = [{
    id         = cloudflare_zero_trust_access_policy.internal[0].id
    precedence = var.cloudflare_access_policy_precedence
  }]
}

resource "cloudflare_zero_trust_access_policy" "internal" {
  count = local.cloudflare_access_enabled ? 1 : 0

  account_id = local.cloudflare_account_id
  name       = local.cloudflare_access_policy_name
  decision   = var.cloudflare_access_policy_decision

  include = concat(
    var.internal_access_group_object_id != "" ? [{
      azure_ad = {
        identity_provider_id = local.cloudflare_idp_id
        id                   = var.internal_access_group_object_id
      }
    }] : [],
    var.internal_access_email_domain != "" ? [{
      email_domain = { domain = var.internal_access_email_domain }
    }] : [],
    length(var.internal_access_emails) > 0 ? [
      for e in var.internal_access_emails : { email = { email = e } }
    ] : [],
  )
}
