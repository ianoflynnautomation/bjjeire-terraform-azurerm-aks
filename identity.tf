
locals {
  workload_identity_audience = ["api://AzureADTokenExchange"]
  github_oidc_issuer         = "https://token.actions.githubusercontent.com"

  fic_name_external_secrets         = "fic-external-secrets"
  fic_name_bjjeire_api              = "fic-bjjeire-api"
  fic_name_bjjeire_seeder           = "fic-bjjeire-seeder"
  fic_name_flux_source              = "fic-flux-source-controller"
  fic_name_flux_kustomize           = "fic-flux-kustomize-controller"
  fic_name_flux_helm                = "fic-flux-helm-controller"
  fic_name_flux_image_reflector     = "fic-flux-image-reflector"
  fic_name_flux_image_automation    = "fic-flux-image-automation"
  fic_name_flux_notification        = "fic-flux-notification-controller"
  fic_name_gha_prenv_pull_request   = "fic-gha-prenv-pull-request"
  fic_name_gha_prenv_main           = "fic-gha-prenv-main"
  fic_name_gha_prenv_bjjeire_pr     = "fic-gha-prenv-bjjeire-pull-request"
  fic_subject_external_secrets      = "system:serviceaccount:external-secrets:external-secrets"
  fic_subject_bjjeire_api           = "system:serviceaccount:bjjeire:bjjeire-api"
  fic_subject_bjjeire_seeder        = "system:serviceaccount:bjjeire:bjjeire-seeder"
  fic_subject_flux_source           = "system:serviceaccount:flux-system:source-controller"
  fic_subject_flux_kustomize        = "system:serviceaccount:flux-system:kustomize-controller"
  fic_subject_flux_helm             = "system:serviceaccount:flux-system:helm-controller"
  fic_subject_flux_image_reflector  = "system:serviceaccount:flux-system:image-reflector-controller"
  fic_subject_flux_image_automation = "system:serviceaccount:flux-system:image-automation-controller"
  fic_subject_flux_notification     = "system:serviceaccount:flux-system:notification-controller"

  fic_subject_gha_prenv_tests_pr   = "repo:${var.github_org}/${var.gha_pr_env_tests_repo}:pull_request"
  fic_subject_gha_prenv_tests_main = "repo:${var.github_org}/${var.gha_pr_env_tests_repo}:ref:refs/heads/${var.gha_pr_env_main_branch}"
  fic_subject_gha_prenv_bjjeire_pr = "repo:${var.github_org}/${var.github_repo}:pull_request"

  rk_aks_cluster_user           = "aks_cluster_user"
  rk_aks_pr_env_namespace_admin = "aks_pr_env_namespace_admin"
}

module "cluster_identity" {
  source = "./modules/user-assigned-identity"

  name                = "${var.cluster_identity_name_prefix}${var.environment}-${var.location_short_name}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  tags                = var.tags

  role_assignments = {
    aks_vnet = {
      role_definition_id_or_name = var.cluster_identity_vnet_role_name
      scope                      = module.virtual_network.resource_id
    }
  }
}

resource "azurerm_role_definition" "aks_pr_env_namespace_admin" {
  name        = format(var.aks_pr_env_role_name_format, var.environment)
  scope       = module.aks.aks_id
  description = var.aks_pr_env_role_description

  permissions {
    actions      = var.aks_pr_env_role_actions
    not_actions  = var.aks_pr_env_role_not_actions
    data_actions = var.aks_pr_env_role_data_actions
  }

  assignable_scopes = [module.aks.aks_id]
}

module "workload_identities" {
  source = "./modules/workload-identities"

  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  tags                = var.tags

  identities = {
    external_secrets = {
      name = "${var.external_secrets_identity_name_prefix}${var.environment}-${var.location_short_name}"
      federated_identity_credentials = {
        external_secrets = {
          audience = local.workload_identity_audience
          issuer   = module.aks.oidc_issuer_url
          name     = local.fic_name_external_secrets
          subject  = local.fic_subject_external_secrets
        }
      }
    }

    api = {
      name = "${var.api_identity_name_prefix}${var.environment}-${var.location_short_name}"
      federated_identity_credentials = {
        bjjeire_api = {
          audience = local.workload_identity_audience
          issuer   = module.aks.oidc_issuer_url
          name     = local.fic_name_bjjeire_api
          subject  = local.fic_subject_bjjeire_api
        }
      }
    }

    seeder = {
      name = "${var.seeder_identity_name_prefix}${var.environment}-${var.location_short_name}"
      federated_identity_credentials = {
        bjjeire_seeder = {
          audience = local.workload_identity_audience
          issuer   = module.aks.oidc_issuer_url
          name     = local.fic_name_bjjeire_seeder
          subject  = local.fic_subject_bjjeire_seeder
        }
      }
    }

    flux = {
      name = "${var.flux_identity_name_prefix}${var.environment}-${var.location_short_name}"
      federated_identity_credentials = {
        flux_source_controller = {
          audience = local.workload_identity_audience
          issuer   = module.aks.oidc_issuer_url
          name     = local.fic_name_flux_source
          subject  = local.fic_subject_flux_source
        }
        flux_kustomize_controller = {
          audience = local.workload_identity_audience
          issuer   = module.aks.oidc_issuer_url
          name     = local.fic_name_flux_kustomize
          subject  = local.fic_subject_flux_kustomize
        }
        flux_helm_controller = {
          audience = local.workload_identity_audience
          issuer   = module.aks.oidc_issuer_url
          name     = local.fic_name_flux_helm
          subject  = local.fic_subject_flux_helm
        }
        flux_image_reflector_controller = {
          audience = local.workload_identity_audience
          issuer   = module.aks.oidc_issuer_url
          name     = local.fic_name_flux_image_reflector
          subject  = local.fic_subject_flux_image_reflector
        }
        flux_image_automation_controller = {
          audience = local.workload_identity_audience
          issuer   = module.aks.oidc_issuer_url
          name     = local.fic_name_flux_image_automation
          subject  = local.fic_subject_flux_image_automation
        }
        flux_notification_controller = {
          audience = local.workload_identity_audience
          issuer   = module.aks.oidc_issuer_url
          name     = local.fic_name_flux_notification
          subject  = local.fic_subject_flux_notification
        }
      }
    }

    gha_pr_env = {
      name = "${var.gha_pr_env_identity_name_prefix}${var.environment}-${var.location_short_name}"
      federated_identity_credentials = {
        pull_request = {
          audience = local.workload_identity_audience
          issuer   = local.github_oidc_issuer
          name     = local.fic_name_gha_prenv_pull_request
          subject  = local.fic_subject_gha_prenv_tests_pr
        }
        main = {
          audience = local.workload_identity_audience
          issuer   = local.github_oidc_issuer
          name     = local.fic_name_gha_prenv_main
          subject  = local.fic_subject_gha_prenv_tests_main
        }
        bjjeire_pull_request = {
          audience = local.workload_identity_audience
          issuer   = local.github_oidc_issuer
          name     = local.fic_name_gha_prenv_bjjeire_pr
          subject  = local.fic_subject_gha_prenv_bjjeire_pr
        }
      }
      role_assignments = {
        (local.rk_aks_cluster_user) = {
          role_definition_id_or_name = var.gha_pr_env_aks_user_role_name
          scope                      = module.aks.aks_id
        }
        (local.rk_aks_pr_env_namespace_admin) = {
          role_definition_id_or_name = azurerm_role_definition.aks_pr_env_namespace_admin.role_definition_resource_id
          scope                      = module.aks.aks_id
        }
      }
    }
  }
}

moved {
  from = module.external_secrets_identity
  to   = module.workload_identities.module.identity["external_secrets"]
}

moved {
  from = module.api_identity
  to   = module.workload_identities.module.identity["api"]
}

moved {
  from = module.seeder_identity
  to   = module.workload_identities.module.identity["seeder"]
}

moved {
  from = module.flux_identity
  to   = module.workload_identities.module.identity["flux"]
}

moved {
  from = module.gha_pr_env_identity
  to   = module.workload_identities.module.identity["gha_pr_env"]
}

output "bjjeire_api_identity_client_id" {
  description = "Client ID of the bjjeire-api workload identity. Used by the api ServiceAccount annotation."
  value       = module.workload_identities.client_ids["api"]
}

output "bjjeire_seeder_identity_client_id" {
  description = "Client ID of the bjjeire-seeder workload identity. Used by the seeder Job ServiceAccount annotation."
  value       = module.workload_identities.client_ids["seeder"]
}

output "gha_pr_env_identity_client_id" {
  description = "Client ID of the GitHub Actions PR-env identity. Set as AZURE_CLIENT_ID secret in bjjeire-tests + BjjEire repos for the pr-env.yml workflow."
  value       = module.workload_identities.client_ids["gha_pr_env"]
}
