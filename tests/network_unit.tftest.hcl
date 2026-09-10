mock_provider "azurerm" {
  override_during = plan

  mock_data "azurerm_client_config" {
    defaults = {
      tenant_id       = "11111111-1111-1111-1111-111111111111"
      client_id       = "22222222-2222-2222-2222-222222222222"
      object_id       = "33333333-3333-3333-3333-333333333333"
      subscription_id = "00000000-0000-0000-0000-000000000000"
    }
  }

  mock_data "azurerm_storage_account" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-state-test-weu-01/providers/Microsoft.Storage/storageAccounts/stakstestweu01"
    }
  }
}

mock_provider "azuread" {
  override_during = plan

  mock_data "azuread_group" {
    defaults = {
      object_id = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
    }
  }
}

mock_provider "cloudflare" {
  override_during = plan
}

mock_provider "github" {
  override_during = plan
}

override_module {
  target = module.rg
  outputs = {
    name        = "rg-aks-test-weu-01"
    location    = "switzerlandnorth"
    resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-aks-test-weu-01"
  }
}

override_module {
  target = module.nat_gateway
  outputs = {
    resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-aks-test-weu-01/providers/Microsoft.Network/natGateways/natgw-aks-test-staging-weu-01"
  }
}

override_module {
  target = module.virtual_network
  outputs = {
    resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-aks-test-weu-01/providers/Microsoft.Network/virtualNetworks/vnet-aks-test-weu-01"
    subnets = {
      system = {
        resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-aks-test-weu-01/providers/Microsoft.Network/virtualNetworks/vnet-aks-test-weu-01/subnets/SystemSubnet"
      }
      workload = {
        resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-aks-test-weu-01/providers/Microsoft.Network/virtualNetworks/vnet-aks-test-weu-01/subnets/RunnerSubnet"
      }
      private_endpoints = {
        resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-aks-test-weu-01/providers/Microsoft.Network/virtualNetworks/vnet-aks-test-weu-01/subnets/PrivateEndpointSubnet"
      }
    }
  }
}

override_module {
  target = module.kv_private_dns_zone
  outputs = {
    resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-aks-test-weu-01/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net"
  }
}

override_module {
  target = module.cluster_identity
  outputs = {
    resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-aks-test-weu-01/providers/Microsoft.ManagedIdentity/userAssignedIdentities/uami-cp-staging-swn"
  }
}

override_module {
  target = module.aks
  outputs = {
    resource_id                    = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-aks-test-weu-01/providers/Microsoft.ContainerService/managedClusters/aks-test-staging-weu-01"
    oidc_issuer_profile_issuer_url = "https://switzerlandnorth.oic.prod-aks.azure.com/11111111-1111-1111-1111-111111111111/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/"
  }
}

override_module {
  target = module.workload_node_pools["apps"]
}

override_module {
  target = module.workload_node_pools["runners"]
}

override_module {
  target = module.workload_identities
  outputs = {
    principal_ids = {
      external_secrets  = "aaaaaaaa-0000-0000-0000-000000000001"
      api               = "aaaaaaaa-0000-0000-0000-000000000002"
      seeder            = "aaaaaaaa-0000-0000-0000-000000000003"
      flux              = "aaaaaaaa-0000-0000-0000-000000000004"
      tests_runner      = "aaaaaaaa-0000-0000-0000-000000000005"
      gha_terraform     = "aaaaaaaa-0000-0000-0000-000000000006"
      gha_pr_env        = "aaaaaaaa-0000-0000-0000-000000000007"
      gha_atest_history = "aaaaaaaa-0000-0000-0000-000000000008"
    }
    client_ids = {
      external_secrets  = "bbbbbbbb-0000-0000-0000-000000000001"
      api               = "bbbbbbbb-0000-0000-0000-000000000002"
      seeder            = "bbbbbbbb-0000-0000-0000-000000000003"
      flux              = "bbbbbbbb-0000-0000-0000-000000000004"
      tests_runner      = "bbbbbbbb-0000-0000-0000-000000000005"
      gha_terraform     = "bbbbbbbb-0000-0000-0000-000000000006"
      gha_pr_env        = "bbbbbbbb-0000-0000-0000-000000000007"
      gha_atest_history = "bbbbbbbb-0000-0000-0000-000000000008"
    }
  }
}

override_module {
  target = module.key_vault
  outputs = {
    uri = "https://kv-aks-test-weu-01.vault.azure.net/"
    keys = {
      sops-encryption-key = {
        id = "https://kv-aks-test-weu-01.vault.azure.net/keys/sops-encryption-key/00000000000000000000000000000000"
      }
    }
  }
}

override_module {
  target = module.storage_images
  outputs = {
    fqdn = {
      blob = "staksimagestest01.blob.core.windows.net"
    }
  }
}

override_module {
  target = module.bjjeire_app_registrations
  outputs = {
    api_client_id                   = "cccccccc-0000-0000-0000-000000000001"
    spa_client_id                   = "cccccccc-0000-0000-0000-000000000002"
    tests_client_id                 = "cccccccc-0000-0000-0000-000000000003"
    tests_client_secret             = "test-not-a-real-secret"
    api_audience                    = "api://bjjeire-api-staging"
    api_service_principal_object_id = "cccccccc-0000-0000-0000-000000000010"
  }
}

override_module {
  target = module.app_reg_oauth2_proxy
  outputs = {
    id        = "/applications/cccccccc-0000-0000-0000-000000000020"
    client_id = "cccccccc-0000-0000-0000-000000000021"
  }
}

override_module {
  target = module.budget
}

override_module {
  target = module.entra_diagnostic_setting
}

override_module {
  target = module.cloudflare_access_idp
  outputs = {
    tests_service_token_enabled       = false
    tests_service_token_client_id     = null
    tests_service_token_client_secret = null
  }
}

override_module {
  target = module.cloudflare_zone
}

variables {
  subscription_id                     = "00000000-0000-0000-0000-000000000000"
  private_email                       = "test@example.com"
  resource_group_name                 = "rg-aks-test-weu-01"
  environment                         = "staging"
  storage_account_name                = "stakstestweu01"
  state_resource_group_name           = "rg-state-test-weu-01"
  aks_cluster_name                    = "aks-test-staging-weu-01"
  cloudflare_api_token                = "test-cloudflare-token"
  github_app_id                       = "1"
  github_app_installation_id          = "1"
  github_app_private_key              = <<-EOT
    -----BEGIN TESTING PRIVATE KEY-----
    not-a-real-key
    -----END TESTING PRIVATE KEY-----
  EOT
  github_token                        = "test-github-token"
  ghcr_pat                            = "test-ghcr-pat"
  github_org                          = "example-org"
  github_repo                         = "example-terraform"
  storage_images_account_name         = "staksimagestest01"
  kv_name                             = "kv-aks-test-weu-01"
  vnet_name                           = "vnet-aks-test-weu-01"
  vnet_address_space                  = ["10.20.0.0/16"]
  aks_ssh_key_rsa_bits                = 2048
  enable_cloudflare_tunnel            = false
  enable_cloudflare_origin_lockdown   = false
  spa_redirect_uris                   = ["https://test.example.com/"]
  aks_rbac_aad_admin_group_object_ids = ["bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb"]
}

run "fails_when_nat_gateway_sku_is_invalid" {
  command = plan

  variables {
    nat_gateway_sku_name = "Basic"
  }

  expect_failures = [
    var.nat_gateway_sku_name,
  ]
}

run "node_subnets_disable_default_outbound_and_use_nat" {
  command = plan

  assert {
    condition     = toset(keys(local.subnets)) == toset(["system", "workload", "private_endpoints"])
    error_message = "Expected exactly the system, workload, and private_endpoints subnets."
  }

  assert {
    condition = (
      local.subnets.system.default_outbound_access_enabled == false
      && local.subnets.workload.default_outbound_access_enabled == false
      && local.subnets.private_endpoints.default_outbound_access_enabled == false
    )
    error_message = "Every subnet must disable default outbound access (implicit Azure SNAT)."
  }

  assert {
    condition = (
      local.subnets.system.nat_gateway.id == module.nat_gateway.resource_id
      && local.subnets.workload.nat_gateway.id == module.nat_gateway.resource_id
    )
    error_message = "System and workload subnets must SNAT through the NAT Gateway."
  }

  assert {
    condition     = try(local.subnets.private_endpoints.nat_gateway, null) == null
    error_message = "The private-endpoint subnet is inbound-only and must not be NATed."
  }

  assert {
    condition = (
      local.subnets.system.private_endpoint_network_policies == "Enabled"
      && local.subnets.workload.private_endpoint_network_policies == "Enabled"
      && local.subnets.private_endpoints.private_endpoint_network_policies == "Disabled"
    )
    error_message = "PE network policies must be Disabled only on the private-endpoints subnet."
  }
}

run "nat_gateway_names_default_from_cluster_name" {
  command = plan

  assert {
    condition     = local.nat_gateway_name == "natgw-aks-test-staging-weu-01"
    error_message = "NAT Gateway name must default to natgw-<aks_cluster_name>."
  }

  assert {
    condition     = local.nat_gateway_public_ip_name == "pip-natgw-aks-test-staging-weu-01"
    error_message = "NAT public IP name must default to pip-natgw-<aks_cluster_name>."
  }

  assert {
    condition     = local.nat_gateway_public_ip_sku == "Standard"
    error_message = "Standard NAT SKU must pair with a Standard public IP."
  }
}

run "nat_gateway_standardv2_pairs_zone_redundant_public_ip" {
  command = plan

  variables {
    nat_gateway_sku_name = "StandardV2"
  }

  assert {
    condition     = local.nat_gateway_public_ip_sku == "StandardV2"
    error_message = "StandardV2 NAT SKU must pair with a StandardV2 public IP."
  }
}

run "workload_subnet_has_no_nsg_when_origin_lockdown_disabled" {
  command = plan

  assert {
    condition     = local.subnets.workload.network_security_group == null
    error_message = "Workload subnet must not attach an NSG when origin lockdown is off."
  }
}

run "workload_subnet_attaches_nsg_when_origin_lockdown_enabled" {
  command = plan

  variables {
    enable_cloudflare_origin_lockdown = true
  }

  override_module {
    target = module.cloudflare_ingress_nsg[0]
    outputs = {
      resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-aks-test-weu-01/providers/Microsoft.Network/networkSecurityGroups/aks-test-staging-weu-01-cf"
    }
  }

  assert {
    condition     = local.subnets.workload.network_security_group.id == module.cloudflare_ingress_nsg[0].resource_id
    error_message = "Origin lockdown must attach the Cloudflare ingress NSG to the workload subnet only."
  }

  assert {
    condition     = try(local.subnets.system.network_security_group, null) == null
    error_message = "The system subnet must not receive the Cloudflare ingress NSG."
  }
}

run "cloudflare_ipv4_defaults_when_override_empty" {
  command = plan

  assert {
    condition     = toset(local.cloudflare_ipv4_effective) == toset(local.cloudflare_ipv4_default)
    error_message = "Empty cloudflare_ipv4_ranges must fall back to the bundled Cloudflare IPv4 snapshot."
  }

  assert {
    condition     = contains(local.cloudflare_ipv4_effective, "173.245.48.0/20")
    error_message = "Default Cloudflare IPv4 snapshot must include 173.245.48.0/20."
  }
}

run "cloudflare_ipv4_override_replaces_defaults" {
  command = plan

  variables {
    cloudflare_ipv4_ranges = ["203.0.113.0/24"]
  }

  assert {
    condition     = toset(local.cloudflare_ipv4_effective) == toset(["203.0.113.0/24"])
    error_message = "A non-empty cloudflare_ipv4_ranges override must replace the bundled snapshot."
  }
}
