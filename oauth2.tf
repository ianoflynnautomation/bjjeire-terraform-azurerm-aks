locals {
  oauth2_proxy_app_name     = "${var.oauth2_proxy_app_name_prefix}${var.aks_cluster_name}"
  oauth2_proxy_callback_uri = "https://${var.oauth2_proxy_callback_subdomain}.${var.cluster_domain}${var.oauth2_proxy_callback_path}"
}

module "app_reg_oauth2_proxy" {
  source = "./modules/app-registration"

  display_name      = local.oauth2_proxy_app_name
  owners            = var.app_registration_owner_object_ids
  web_redirect_uris = [local.oauth2_proxy_callback_uri]

  optional_claims = {
    id_token = var.oauth2_proxy_optional_id_token_claims
  }

  group_membership_claims = var.oauth2_proxy_group_membership_claims
}

resource "time_rotating" "oauth2_proxy_secret" {
  rotation_days = var.oauth2_proxy_secret_rotation_days
}

resource "azuread_application_password" "oauth2_proxy" {
  application_id = module.app_reg_oauth2_proxy.id
  display_name   = var.oauth2_proxy_secret_display_name
  end_date       = timeadd(time_rotating.oauth2_proxy_secret.rotation_rfc3339, var.oauth2_proxy_secret_validity)

  rotate_when_changed = {
    rotation = time_rotating.oauth2_proxy_secret.id
  }
}

resource "random_password" "oauth2_cookie_secret" {
  length  = var.oauth2_proxy_cookie_secret_length
  special = false
}
