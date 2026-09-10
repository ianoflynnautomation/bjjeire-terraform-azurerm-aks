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

run "key_vault_public_data_plane_stays_enabled" {
  command = plan

  assert {
    condition     = var.kv_public_network_access_enabled == true
    error_message = "ADR-0002: kv_public_network_access_enabled must stay true so GitHub-hosted apply can write secrets."
  }
}

run "key_vault_rbac_is_exactly_apply_principal_and_in_cluster_readers" {
  command = plan

  assert {
    condition     = toset(keys(local.kv_role_assignments)) == toset(["terraform_runner", "external_secrets_kv_secret_user", "flux_kv_secrets_user"])
    error_message = "Key Vault RBAC must be exactly apply-principal admin plus External Secrets and Flux Secrets User."
  }

  assert {
    condition     = local.kv_role_assignments.terraform_runner.role_definition_id_or_name == "Key Vault Administrator"
    error_message = "The apply principal must be Key Vault Administrator (no access policies)."
  }

  assert {
    condition = (
      local.kv_role_assignments.external_secrets_kv_secret_user.role_definition_id_or_name == "Key Vault Secrets User"
      && local.kv_role_assignments.flux_kv_secrets_user.role_definition_id_or_name == "Key Vault Secrets User"
    )
    error_message = "In-cluster identities must be Secrets User, not Administrator."
  }
}

run "key_vault_private_endpoint_lands_on_pe_subnet" {
  command = plan

  assert {
    condition     = contains(keys(local.kv_private_endpoints), "vault")
    error_message = "The vault private endpoint must always be merged into kv_private_endpoints."
  }

  assert {
    condition     = local.kv_private_endpoints.vault.subnet_resource_id == module.virtual_network.subnets["private_endpoints"].resource_id
    error_message = "The vault private endpoint must sit on the private-endpoints subnet."
  }
}

run "images_account_rejects_public_blobs_and_account_keys" {
  command = plan

  assert {
    condition     = var.storage_images_allow_nested_items_to_be_public == false
    error_message = "Image blobs must not be anonymously readable at the account."
  }

  assert {
    condition     = var.storage_images_shared_access_key_enabled == false
    error_message = "Image storage must not allow account-key auth; workloads use UAMI RBAC."
  }

  assert {
    condition     = var.storage_images_https_traffic_only_enabled == true
    error_message = "Image storage must reject non-HTTPS."
  }

  assert {
    condition     = var.storage_images_min_tls_version == "TLS1_2"
    error_message = "Image storage must require TLS 1.2 or higher."
  }
}

run "atest_history_disabled_when_account_name_empty" {
  command = plan

  assert {
    condition     = local.atest_history_enabled == false
    error_message = "Empty storage_atest_account_name must disable the atest history account and identity."
  }
}

run "atest_history_enabled_when_account_name_set" {
  command = plan

  variables {
    storage_atest_account_name = "statestweu01"
  }

  override_module {
    target = module.storage_atest_history[0]
    outputs = {
      name = "statestweu01"
    }
  }

  assert {
    condition     = local.atest_history_enabled == true
    error_message = "A non-empty storage_atest_account_name must opt the environment into atest history."
  }

  assert {
    condition     = output.storage_atest_history_url == "azblob://statestweu01/atest-history"
    error_message = "ATEST_HISTORY_URL must be azblob://<account>/<container> with no query string (PRs append ?readonly=1 in CI)."
  }
}

run "fails_when_atest_account_name_has_uppercase" {
  command = plan

  variables {
    storage_atest_account_name = "STAtestWEU01"
  }

  expect_failures = [
    var.storage_atest_account_name,
  ]
}

run "fails_when_atest_container_allows_public_access" {
  command = plan

  variables {
    storage_atest_account_name = "statestweu01"
    storage_atest_containers = {
      atest-history = {
        name          = "atest-history"
        public_access = "Blob"
      }
    }
  }

  expect_failures = [
    var.storage_atest_containers,
  ]
}
