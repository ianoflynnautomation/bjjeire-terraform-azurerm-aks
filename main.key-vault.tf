locals {
  kv_secret_definitions = {
    aks_public_ssh_key = {
      name         = "aks-ssh-public-key"
      content_type = "text/plain"
    }
    aks_private_ssh_key = {
      name         = "aks-ssh-private-key"
      content_type = "text/plain"
    }
    github_app_id = {
      name         = "github-app-id"
      content_type = "text/plain"
    }
    github_app_installation_id = {
      name         = "github-app-installation-id"
      content_type = "text/plain"
    }
    github_app_private_key = {
      name         = "github-app-private-key"
      content_type = "application/x-pem-file"
    }
    grafana_admin_password = {
      name         = "grafana-admin-password"
      content_type = "text/plain"
    }
    cloudflare_api_token = {
      name         = "cloudflare-api-token"
      content_type = "text/plain"
    }
    cloudflare_tunnel_token = {
      name         = "cloudflare-tunnel-token"
      content_type = "text/plain"
    }
    private_email = {
      name         = "private-email-address"
      content_type = "text/plain"
    }
    oauth2_proxy_cookie_secret = {
      name         = "oauth2-proxy-cookie-secret"
      content_type = "text/plain"
    }
    oauth2_proxy_client_secret = {
      name         = "oauth2-proxy-client-secret"
      content_type = "text/plain"
    }

    bjj_donation_bitcoin_address = {
      name         = "bjj-donation-bitcoin-address"
      content_type = "text/plain"
    }
    bjj_api_azuread_tenant_id = {
      name         = "bjj-api-azuread-tenant-id"
      content_type = "text/plain"
    }
    bjj_api_azuread_client_id = {
      name         = "bjj-api-azuread-client-id"
      content_type = "text/plain"
    }
    bjj_api_azuread_audience = {
      name         = "bjj-api-azuread-audience"
      content_type = "text/plain"
    }
    bjj_tests_azuread_client_id = {
      name         = "bjj-tests-azuread-client-id"
      content_type = "text/plain"
    }
    bjj_tests_azuread_client_secret = {
      name         = "bjj-tests-azuread-client-secret"
      content_type = "text/plain"
    }
    bjj_tests_cf_access_client_id = {
      name         = "bjj-tests-cf-access-client-id"
      content_type = "text/plain"
    }
    bjj_tests_cf_access_client_secret = {
      name         = "bjj-tests-cf-access-client-secret"
      content_type = "text/plain"
    }
    bjj_tests_pw_user = {
      name         = "bjj-tests-pw-user"
      content_type = "text/plain"
    }
    bjj_tests_pw_password = {
      name         = "bjj-tests-pw-password"
      content_type = "text/plain"
    }
    ghcr_pat = {
      name         = "ghcr-pat"
      content_type = "text/plain"
    }
    bjj_mongodb_root_password = {
      name         = "bjj-mongodb-root-password"
      content_type = "text/plain"
    }
  }

  kv_secret_values = {
    aks_public_ssh_key         = tls_private_key.aks_ssh_key.public_key_openssh
    aks_private_ssh_key        = tls_private_key.aks_ssh_key.private_key_pem
    github_app_id              = var.github_app_id
    github_app_installation_id = var.github_app_installation_id
    github_app_private_key     = var.github_app_private_key
    grafana_admin_password     = var.grafana_admin_password
    cloudflare_api_token       = var.cloudflare_api_token
    # Prefer the token derived from the Terraform-managed tunnel. Fall back
    # to var.cloudflare_tunnel_token only when enable_cloudflare_tunnel = false
    # (e.g. tunnel pre-existing and managed manually).
    cloudflare_tunnel_token = (
      var.enable_cloudflare_tunnel
      ? module.cloudflare_tunnel.token
      : var.cloudflare_tunnel_token
    )
    private_email                = var.private_email
    oauth2_proxy_cookie_secret   = base64encode(random_password.oauth2_cookie_secret.result)
    oauth2_proxy_client_secret   = azuread_application_password.oauth2_proxy.value
    bjj_api_azuread_tenant_id    = data.azurerm_client_config.current.tenant_id
    bjj_api_azuread_client_id    = module.bjjeire_app_registrations.api_client_id
    bjj_api_azuread_audience     = module.bjjeire_app_registrations.api_audience
    # Empty-string fallbacks keep the secret schema stable when the tests app
    # registration / CF service token are toggled off. CI jobs that pull these
    # must treat empty values as "auth disabled in this environment".
    bjj_tests_azuread_client_id     = module.bjjeire_app_registrations.tests_client_id
    bjj_tests_azuread_client_secret = module.bjjeire_app_registrations.tests_client_secret
    bjj_tests_cf_access_client_id = (
      module.cloudflare_access_idp.tests_service_token_client_id != null
      ? module.cloudflare_access_idp.tests_service_token_client_id
      : ""
    )
    bjj_tests_cf_access_client_secret = (
      module.cloudflare_access_idp.tests_service_token_client_secret != null
      ? module.cloudflare_access_idp.tests_service_token_client_secret
      : ""
    )
    bjj_tests_pw_user = (
      length(azuread_user.playwright_test) > 0
      ? azuread_user.playwright_test[0].user_principal_name
      : ""
    )
    bjj_tests_pw_password = (
      length(random_password.playwright_test_user) > 0
      ? random_password.playwright_test_user[0].result
      : ""
    )
    bjj_donation_bitcoin_address = var.donation_bitcoin_address
    ghcr_pat                     = var.ghcr_pat
    bjj_mongodb_root_password    = random_password.bjj_mongodb_root_password.result
  }

  kv_role_assignments = {
    terraform_runner = {
      role_definition_id_or_name = "Key Vault Administrator"
      principal_id               = data.azurerm_client_config.current.object_id
    }
    external_secrets_kv_secret_user = {
      role_definition_id_or_name = "Key Vault Secrets User"
      principal_id               = module.workload_identities.principal_ids["external_secrets"]
    }
    flux_kv_secrets_user = {
      role_definition_id_or_name = "Key Vault Secrets User"
      principal_id               = module.workload_identities.principal_ids["flux"]
    }
  }
}

module "key_vault" {
  source = "git::https://github.com/Azure/terraform-azurerm-avm-res-keyvault-vault.git?ref=3735ca49887857467f3030ad72fd43705e1eb387" #v0.10.2

  location                                = azurerm_resource_group.rg.location
  name                                    = var.kv_name
  resource_group_name                     = azurerm_resource_group.rg.name
  tenant_id                               = data.azurerm_client_config.current.tenant_id
  contacts                                = var.kv_contacts
  diagnostic_settings                     = var.kv_diagnostic_settings
  enable_telemetry                        = var.kv_enable_telemetry
  enabled_for_deployment                  = var.kv_enabled_for_deployment
  enabled_for_disk_encryption             = var.kv_enabled_for_disk_encryption
  enabled_for_template_deployment         = var.kv_enabled_for_template_deployment
  keys                                    = var.kv_keys
  legacy_access_policies                  = var.kv_legacy_access_policies
  legacy_access_policies_enabled          = var.kv_legacy_access_policies_enabled
  lock                                    = var.kv_lock
  network_acls                            = var.kv_network_acls
  private_endpoints                       = var.kv_private_endpoints
  private_endpoints_manage_dns_zone_group = var.kv_private_endpoints_manage_dns_zone_group
  public_network_access_enabled           = var.kv_public_network_access_enabled
  purge_protection_enabled                = var.kv_purge_protection_enabled
  role_assignments                        = local.kv_role_assignments
  secrets                                 = local.kv_secret_definitions
  secrets_value                           = local.kv_secret_values
  sku_name                                = var.kv_sku_name
  soft_delete_retention_days              = var.kv_soft_delete_retention_days
  tags                                    = var.tags
  wait_for_rbac_before_contact_operations = var.kv_wait_for_rbac_before_contact_operations
  wait_for_rbac_before_key_operations     = var.kv_wait_for_rbac_before_key_operations
  wait_for_rbac_before_secret_operations  = var.kv_wait_for_rbac_before_secret_operations
}
