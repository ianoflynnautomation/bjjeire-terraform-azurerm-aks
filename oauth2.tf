locals {
  oauth2_proxy_app_name     = "oauth2-proxy-${var.aks_cluster_name}"
  oauth2_proxy_callback_uri = "https://oauth2.${var.cluster_domain}/oauth2/callback"
}

module "app_reg_oauth2_proxy" {
  source = "./modules/app-registration"

  display_name      = local.oauth2_proxy_app_name
  owners            = var.app_registration_owner_object_ids
  web_redirect_uris = [local.oauth2_proxy_callback_uri]

  optional_claims = {
    id_token = ["groups"]
  }

  group_membership_claims = ["SecurityGroup"]
}

resource "time_rotating" "oauth2_proxy_secret" {
  rotation_days = 90
}

resource "azuread_application_password" "oauth2_proxy" {
  application_id = module.app_reg_oauth2_proxy.id
  display_name   = "oauth2-proxy-secret"
  end_date       = timeadd(time_rotating.oauth2_proxy_secret.rotation_rfc3339, "720h")

  rotate_when_changed = {
    rotation = time_rotating.oauth2_proxy_secret.id
  }
}

resource "random_password" "oauth2_cookie_secret" {
  length  = 32
  special = false
}
