
resource "azuread_application" "oauth2_proxy" {
  display_name = "oauth2-proxy-${var.aks_cluster_name}"

  web {
    redirect_uris = ["https://oauth2.${var.cluster_domain}/oauth2/callback"]
  }

  group_membership_claims = ["SecurityGroup"]

  optional_claims {
    id_token {
      name = "groups"
    }
  }
}

resource "azuread_service_principal" "oauth2_proxy" {
  client_id = azuread_application.oauth2_proxy.client_id
}

resource "azuread_application_password" "oauth2_proxy" {
  application_id = azuread_application.oauth2_proxy.id
  display_name   = "oauth2-proxy-secret"
  end_date       = timeadd(timestamp(), "8760h")

  lifecycle {
    ignore_changes = [end_date]
  }
}

resource "random_password" "oauth2_cookie_secret" {
  length  = 32
  special = false
}
