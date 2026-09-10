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

run "fails_when_environment_is_invalid" {
  command = plan

  variables {
    environment = "qa"
  }

  expect_failures = [
    var.environment,
  ]
}

run "fails_when_prod_pr_env_enabled" {
  command = plan

  variables {
    environment                            = "prod"
    gha_pr_env_enabled                     = true
    aks_api_server_authorized_ip_ranges    = ["203.0.113.0/24"]
    playwright_test_user_enabled           = false
    cloudflare_tests_service_token_enabled = false
  }

  expect_failures = [
    var.gha_pr_env_enabled,
  ]
}

run "fails_when_prod_github_oidc_management_enabled" {
  command = plan

  variables {
    environment                            = "prod"
    github_manage_actions_oidc             = true
    aks_api_server_authorized_ip_ranges    = ["203.0.113.0/24"]
    playwright_test_user_enabled           = false
    cloudflare_tests_service_token_enabled = false
  }

  expect_failures = [
    var.github_manage_actions_oidc,
  ]
}

run "fails_when_prod_playwright_user_enabled" {
  command = plan

  variables {
    environment                            = "prod"
    playwright_test_user_enabled           = true
    aks_api_server_authorized_ip_ranges    = ["203.0.113.0/24"]
    cloudflare_tests_service_token_enabled = false
  }

  expect_failures = [
    var.playwright_test_user_enabled,
  ]
}

run "fails_when_prod_cloudflare_tests_token_enabled" {
  command = plan

  variables {
    environment                            = "prod"
    cloudflare_tests_service_token_enabled = true
    aks_api_server_authorized_ip_ranges    = ["203.0.113.0/24"]
    playwright_test_user_enabled           = false
  }

  expect_failures = [
    var.cloudflare_tests_service_token_enabled,
  ]
}

run "fails_when_dev_missing_preview_pat" {
  command = plan

  variables {
    environment        = "dev"
    github_preview_pat = ""
  }

  expect_failures = [
    var.github_preview_pat,
  ]
}

run "staging_defaults_omit_pr_env_and_github_oidc" {
  command = plan

  assert {
    condition     = local.gha_pr_env_enabled == false
    error_message = "ADR-0008: gha_pr_env must default off when environment is not dev."
  }

  assert {
    condition     = length(azurerm_role_definition.aks_pr_env_namespace_admin) == 0
    error_message = "The PR-env namespace-admin role must not exist on staging."
  }

  assert {
    condition     = local.github_manage_actions_oidc == false
    error_message = "GitHub Actions OIDC secret management must default off when environment is not dev."
  }

  assert {
    condition     = length(local.github_oidc_repos) == 0 && length(local.github_oidc_secret_names) == 0 && length(local.github_aks_variables) == 0
    error_message = "Staging must not write AZURE_CLIENT_ID / AKS_* onto app or tests repos."
  }

  assert {
    condition     = local.playwright_test_user_enabled == false
    error_message = "Playwright test user stays off unless an environment opts in."
  }
}

run "dev_defaults_enable_pr_env_and_github_oidc" {
  command = plan

  variables {
    environment        = "dev"
    github_preview_pat = "test-preview-pat"
  }

  assert {
    condition     = local.gha_pr_env_enabled == true
    error_message = "ADR-0008: gha_pr_env must default on for environment=dev."
  }

  assert {
    condition     = length(azurerm_role_definition.aks_pr_env_namespace_admin) == 1
    error_message = "Dev must create the PR-env namespace-admin custom role."
  }

  assert {
    condition     = azurerm_role_definition.aks_pr_env_namespace_admin[0].name == "AKS PR-env Namespace Admin (dev)"
    error_message = "PR-env role display name must include the environment."
  }

  assert {
    condition     = local.github_manage_actions_oidc == true
    error_message = "Dev must manage GitHub Actions OIDC secrets so a UAMI recreate cannot leave AADSTS700016."
  }

  assert {
    condition     = local.github_oidc_repos == toset(["bjjeire", "bjjeire-tests"])
    error_message = "OIDC secrets must be written to both the app and tests repos."
  }

  assert {
    condition = (
      contains(local.github_oidc_secret_names, "AZURE_CLIENT_ID")
      && contains(local.github_oidc_secret_names, "AZURE_TESTS_CLIENT_SECRET")
      && !contains(local.github_oidc_secret_names, "CF_ACCESS_CLIENT_ID")
      && !contains(local.github_oidc_secret_names, "PW_TEST_USER")
    )
    error_message = "Dev OIDC secrets must include Azure client credentials and omit CF Access / Playwright keys when those features are off."
  }

  assert {
    condition     = contains(keys(local.github_aks_variables), "AKS_CLUSTER_NAME")
    error_message = "Dev must publish AKS_* Actions variables on the app repo."
  }
}

run "staging_can_opt_in_to_pr_env" {
  command = plan

  variables {
    gha_pr_env_enabled = true
  }

  assert {
    condition     = local.gha_pr_env_enabled == true
    error_message = "ADR-0005: staging must be able to override gha_pr_env_enabled on."
  }

  assert {
    condition     = length(azurerm_role_definition.aks_pr_env_namespace_admin) == 1
    error_message = "Opting in on staging must create the PR-env role."
  }
}

run "federated_credential_subjects_use_immutable_format_for_app_repo" {
  command = plan

  assert {
    condition     = local.workload_identity_audience == ["api://AzureADTokenExchange"]
    error_message = "Workload identity audience must be the Azure AD token-exchange App ID URI."
  }

  assert {
    condition     = local.github_oidc_issuer == "https://token.actions.githubusercontent.com"
    error_message = "GitHub OIDC issuer must be token.actions.githubusercontent.com."
  }

  assert {
    condition     = local.fic_subject_gha_prenv_tests_pr == "repo:example-org/bjjeire-tests:pull_request"
    error_message = "Tests-repo PR subject must use the name-only GitHub OIDC format."
  }

  assert {
    condition     = local.fic_subject_gha_prenv_tests_main == "repo:example-org/bjjeire-tests:ref:refs/heads/main"
    error_message = "Tests-repo main subject must pin refs/heads/main."
  }

  assert {
    condition     = local.fic_subject_gha_prenv_bjjeire_pr == "repo:example-org@68143624/bjjeire@1305574865:pull_request"
    error_message = "App-repo PR subject must use GitHub's immutable org@id/repo@id format."
  }

  assert {
    condition     = local.fic_subject_external_secrets == "system:serviceaccount:external-secrets:external-secrets"
    error_message = "External Secrets FIC subject must match the in-cluster ServiceAccount."
  }

  assert {
    condition     = local.fic_subject_tests_runner == "system:serviceaccount:actions-runner-system:gha-runner-scale-set"
    error_message = "ARC runner FIC subject must match the runner ServiceAccount."
  }

  assert {
    condition     = local.gha_terraform_repo_subject == "repo:example-org/example-terraform"
    error_message = "Terraform repo subject must stay name-only when github_terraform_repo_id is empty."
  }

  assert {
    condition     = local.fic_subject_gha_terraform_environment == "repo:example-org/example-terraform:environment:staging"
    error_message = "Terraform CI environment subject must include environment:<env>."
  }
}

run "terraform_ci_subject_uses_immutable_ids_when_repo_id_set" {
  command = plan

  variables {
    github_terraform_repo_id = "99"
  }

  assert {
    condition     = local.gha_terraform_repo_subject == "repo:example-org@68143624/example-terraform@99"
    error_message = "When github_terraform_repo_id is set, the Terraform CI subject must use the immutable org@id/repo@id form."
  }

  assert {
    condition     = local.fic_subject_gha_terraform_main == "repo:example-org@68143624/example-terraform@99:ref:refs/heads/main"
    error_message = "Terraform CI main-branch subject must append refs/heads/main to the immutable repo subject."
  }
}

run "cloudflare_tests_token_name_empty_when_disabled" {
  command = plan

  assert {
    condition     = local.cloudflare_tests_service_token_name == ""
    error_message = "An empty tests-token name is what disables token issuance in the Access module."
  }

  assert {
    condition     = local.cloudflare_idp_enabled == false && local.cloudflare_access_enabled == false
    error_message = "IdP and Access must stay off when the tunnel is disabled."
  }
}

run "cloudflare_tests_token_name_includes_environment_when_enabled" {
  command = plan

  variables {
    cloudflare_tests_service_token_enabled = true
  }

  assert {
    condition     = local.cloudflare_tests_service_token_name == "bjjeire-tests-staging"
    error_message = "Enabled tests token must be named <prefix><environment>."
  }
}
