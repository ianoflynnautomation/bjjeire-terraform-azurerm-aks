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

run "fails_when_aks_cluster_name_is_blank" {
  command = plan

  variables {
    aks_cluster_name = "   "
  }

  expect_failures = [
    var.aks_cluster_name,
  ]
}

run "fails_when_aks_sku_name_is_invalid" {
  command = plan

  variables {
    aks_sku_name = "Paid"
  }

  expect_failures = [
    var.aks_sku_name,
  ]
}

run "fails_when_aks_sku_tier_is_invalid" {
  command = plan

  variables {
    aks_sku_tier = "Enterprise"
  }

  expect_failures = [
    var.aks_sku_tier,
  ]
}

run "fails_when_aks_os_disk_type_is_invalid" {
  command = plan

  variables {
    aks_os_disk_type = "Premium"
  }

  expect_failures = [
    var.aks_os_disk_type,
  ]
}

run "fails_when_aks_outbound_type_is_invalid" {
  command = plan

  variables {
    aks_outbound_type = "userAssignedPublicIp"
  }

  expect_failures = [
    var.aks_outbound_type,
  ]
}

run "fails_when_prod_local_accounts_enabled" {
  command = plan

  variables {
    environment                            = "prod"
    aks_local_account_disabled             = false
    aks_api_server_authorized_ip_ranges    = ["203.0.113.0/24"]
    playwright_test_user_enabled           = false
    cloudflare_tests_service_token_enabled = false
  }

  expect_failures = [
    var.aks_local_account_disabled,
  ]
}

run "fails_when_prod_public_api_missing_authorized_ranges" {
  command = plan

  variables {
    environment                            = "prod"
    aks_private_cluster_enabled            = false
    aks_api_server_authorized_ip_ranges    = null
    playwright_test_user_enabled           = false
    cloudflare_tests_service_token_enabled = false
  }

  expect_failures = [
    var.aks_api_server_authorized_ip_ranges,
  ]
}

run "fails_when_prod_public_api_authorized_ranges_empty" {
  command = plan

  variables {
    environment                            = "prod"
    aks_private_cluster_enabled            = false
    aks_api_server_authorized_ip_ranges    = []
    playwright_test_user_enabled           = false
    cloudflare_tests_service_token_enabled = false
  }

  expect_failures = [
    var.aks_api_server_authorized_ip_ranges,
  ]
}

run "fails_when_authorized_range_is_not_cidr" {
  command = plan

  variables {
    aks_api_server_authorized_ip_ranges = ["not-a-cidr", "203.0.113.0/24"]
  }

  expect_failures = [
    var.aks_api_server_authorized_ip_ranges,
  ]
}

# =============================================================================
# Variable validation — positive cases (ADR-0003)
# =============================================================================

run "accepts_non_prod_with_local_accounts_enabled" {
  command = plan

  variables {
    environment                = "staging"
    aks_local_account_disabled = false
  }

  assert {
    condition     = var.aks_local_account_disabled == false
    error_message = "Non-prod must be allowed to enable local kube-admin accounts."
  }
}

run "accepts_prod_public_api_with_authorized_cidr" {
  command = plan

  variables {
    environment                            = "prod"
    aks_private_cluster_enabled            = false
    aks_api_server_authorized_ip_ranges    = ["203.0.113.0/24"]
    playwright_test_user_enabled           = false
    cloudflare_tests_service_token_enabled = false
  }

  assert {
    condition     = var.aks_private_cluster_enabled == false && length(var.aks_api_server_authorized_ip_ranges) > 0
    error_message = "ADR-0003: prod should keep a public API server constrained by CIDRs."
  }
}

run "accepts_prod_private_cluster_without_authorized_ranges" {
  command = plan

  variables {
    environment                            = "prod"
    aks_private_cluster_enabled            = true
    aks_api_server_authorized_ip_ranges    = null
    playwright_test_user_enabled           = false
    cloudflare_tests_service_token_enabled = false
  }

  assert {
    condition     = var.aks_private_cluster_enabled == true
    error_message = "Private-cluster bypass of the CIDR validation did not stick."
  }
}

run "accepts_non_prod_public_api_without_authorized_ranges" {
  command = plan

  variables {
    environment                         = "staging"
    aks_private_cluster_enabled         = false
    aks_api_server_authorized_ip_ranges = null
  }

  assert {
    condition     = var.aks_api_server_authorized_ip_ranges == null
    error_message = "Dev/staging must be allowed to omit API-server CIDRs."
  }
}

run "default_composition_and_security_posture" {
  command = plan

  assert {
    condition     = toset(keys(local.workload_node_pools)) == toset(["apps", "runners"])
    error_message = "Expected exactly the apps and runners user node pools (system is default_agent_pool)."
  }

  assert {
    condition = (
      local.workload_node_pools["apps"].mode == "User"
      && local.workload_node_pools["apps"].priority == "Regular"
      && local.workload_node_pools["apps"].eviction_policy == null
      && local.workload_node_pools["apps"].spot_max_price == null
      && local.workload_node_pools["apps"].auto_scaling_enabled
      && local.workload_node_pools["apps"].min_count == 1
      && local.workload_node_pools["apps"].max_count == 3
      && local.workload_node_pools["apps"].os_disk_type == "Managed"
      && local.workload_node_pools["apps"].node_labels["workload"] == "apps"
      && length(local.workload_node_pools["apps"].node_taints) == 0
    )
    error_message = "apps pool must be a Regular, autoscale 1-3, Managed-disk user pool with no taints."
  }

  assert {
    condition = (
      local.workload_node_pools["runners"].mode == "User"
      && local.workload_node_pools["runners"].priority == "Spot"
      && local.workload_node_pools["runners"].eviction_policy == "Delete"
      && local.workload_node_pools["runners"].spot_max_price == -1
      && local.workload_node_pools["runners"].auto_scaling_enabled
      && local.workload_node_pools["runners"].min_count == 0
      && local.workload_node_pools["runners"].max_count == 1
      && local.workload_node_pools["runners"].os_disk_type == "Ephemeral"
      && local.workload_node_pools["runners"].node_labels["workload"] == "gha-runner"
      && local.workload_node_pools["runners"].node_labels["kubernetes.azure.com/scalesetpriority"] == "spot"
      && contains(local.workload_node_pools["runners"].node_taints, "dedicated=gha-runner:NoSchedule")
      && contains(local.workload_node_pools["runners"].node_taints, "kubernetes.azure.com/scalesetpriority=spot:NoSchedule")
    )
    error_message = "runners pool must be a Spot (pay-up-to-on-demand) Ephemeral user pool, tainted for gha-runner and spot."
  }

  assert {
    condition = (
      local.workload_node_pools["apps"].vnet_subnet_id == module.virtual_network.subnets["workload"].resource_id
      && local.workload_node_pools["runners"].vnet_subnet_id == module.virtual_network.subnets["workload"].resource_id
    )
    error_message = "Both user pools must land on the workload subnet, not the system subnet."
  }

  assert {
    condition     = local.aks_auto_scaler_profile != null
    error_message = "auto_scaler_profile must be sent to the API when aks_auto_scaler_profile_enabled is true."
  }

  assert {
    condition     = local.aks_defender == null && local.aks_security_profile.defender == null
    error_message = "Defender must be omitted (null) when aks_microsoft_defender_enabled is false."
  }

  assert {
    condition     = local.aks_security_profile.workload_identity.enabled == true
    error_message = "Workload identity must stay enabled; Flux and in-cluster UAMIs depend on it."
  }

  assert {
    condition     = local.aks_admin_group_object_ids_effective == var.aks_rbac_aad_admin_group_object_ids
    error_message = "With no display-name matches, aad_profile must use aks_rbac_aad_admin_group_object_ids."
  }

  assert {
    condition     = var.aks_private_cluster_enabled == false
    error_message = "ADR-0003: API server must stay public; GitHub-hosted plan/apply has no VNet route."
  }

  assert {
    condition     = var.aks_node_public_ip_enabled == false
    error_message = "Nodes must not get public IPs; egress is NAT Gateway."
  }

  assert {
    condition     = var.aks_local_account_disabled == true
    error_message = "Local kube-admin accounts must be disabled by default (Entra ID only)."
  }

  assert {
    condition     = var.aks_oidc_issuer_enabled == true && var.aks_workload_identity_enabled == true
    error_message = "OIDC issuer and workload identity must both be on."
  }

  assert {
    condition     = var.aks_role_based_access_control_enabled == true && var.aks_rbac_aad_azure_rbac_enabled == true
    error_message = "Kubernetes RBAC and Azure RBAC for Kubernetes must both be enabled."
  }

  assert {
    condition     = var.aks_outbound_type == "userAssignedNATGateway"
    error_message = "Egress must be userAssignedNATGateway (node subnets have default outbound access off)."
  }

  assert {
    condition     = var.aks_enable_telemetry == false
    error_message = "AVM telemetry must stay off unless an environment explicitly opts in."
  }
}

run "auto_scaler_profile_null_when_disabled" {
  command = plan

  variables {
    aks_auto_scaler_profile_enabled = false
  }

  assert {
    condition     = local.aks_auto_scaler_profile == null
    error_message = "auto_scaler_profile must be null when aks_auto_scaler_profile_enabled is false so the AVM module omits it."
  }
}

run "defender_enabled_emits_security_monitoring" {
  command = plan

  variables {
    aks_microsoft_defender_enabled = true
  }

  assert {
    condition     = try(local.aks_defender.security_monitoring.enabled, false) == true
    error_message = "Enabling Defender must emit security_profile.defender.security_monitoring.enabled = true."
  }

  assert {
    condition     = local.aks_security_profile.defender == local.aks_defender
    error_message = "security_profile.defender must be the Defender local, not a second ternary."
  }
}

run "admin_group_display_name_lookup_overrides_fallback" {
  command = plan

  variables {
    aks_admin_group_display_names       = ["grp-aks-admins"]
    aks_rbac_aad_admin_group_object_ids = ["bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb"]
  }

  assert {
    condition     = length(local.aks_admin_group_object_ids) == 1
    error_message = "Display-name lookup should resolve exactly one Entra group."
  }

  # The for-expression is a tuple; the fallback variable is list(string).
  # Compare as sets so the ternary's result type does not fail the assert.
  assert {
    condition     = toset(local.aks_admin_group_object_ids_effective) == toset(local.aks_admin_group_object_ids)
    error_message = "Resolved display-name object IDs must win over aks_rbac_aad_admin_group_object_ids."
  }

  assert {
    condition     = toset(local.aks_admin_group_object_ids_effective) != toset(var.aks_rbac_aad_admin_group_object_ids)
    error_message = "Fallback object IDs must not be used when the display-name data source returns matches."
  }
}
