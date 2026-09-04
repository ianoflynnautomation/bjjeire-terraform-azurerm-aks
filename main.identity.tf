
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
  fic_name_gha_prenv_bjjeire_main   = "fic-gha-prenv-bjjeire-main"
  fic_name_tests_runner             = "fic-tests-runner"
  fic_name_gha_atest_history_main   = "fic-gha-atest-history-main"
  fic_name_gha_atest_history_app    = "fic-gha-atest-history-app-main"
  fic_subject_external_secrets      = "system:serviceaccount:external-secrets:external-secrets"
  fic_subject_bjjeire_api           = "system:serviceaccount:bjjeire:bjjeire-api"
  fic_subject_bjjeire_seeder        = "system:serviceaccount:bjjeire:bjjeire-seeder"
  fic_subject_tests_runner          = "system:serviceaccount:actions-runner-system:gha-runner-scale-set"
  fic_subject_flux_source           = "system:serviceaccount:flux-system:source-controller"
  fic_subject_flux_kustomize        = "system:serviceaccount:flux-system:kustomize-controller"
  fic_subject_flux_helm             = "system:serviceaccount:flux-system:helm-controller"
  fic_subject_flux_image_reflector  = "system:serviceaccount:flux-system:image-reflector-controller"
  fic_subject_flux_image_automation = "system:serviceaccount:flux-system:image-automation-controller"
  fic_subject_flux_notification     = "system:serviceaccount:flux-system:notification-controller"

  fic_subject_gha_prenv_tests_pr   = "repo:${var.github_org}/${var.gha_pr_env_tests_repo}:pull_request"
  fic_subject_gha_prenv_tests_main = "repo:${var.github_org}/${var.gha_pr_env_tests_repo}:ref:refs/heads/${var.gha_pr_env_main_branch}"
  # bjjeire was created 2026-07-19, so GitHub issues immutable OIDC subjects
  # (repo:OWNER@OWNER-ID/REPO@REPO-ID:…). bjjeire-tests is older and keeps the name-only format.
  fic_subject_gha_prenv_bjjeire_pr   = "repo:${var.github_org}@${var.github_owner_id}/${var.gha_pr_env_app_repo}@${var.gha_pr_env_app_repo_id}:pull_request"
  fic_subject_gha_prenv_bjjeire_main = "repo:${var.github_org}@${var.github_owner_id}/${var.gha_pr_env_app_repo}@${var.gha_pr_env_app_repo_id}:ref:refs/heads/${var.gha_pr_env_main_branch}"

  rk_aks_cluster_user           = "aks_cluster_user"
  rk_aks_pr_env_namespace_admin = "aks_pr_env_namespace_admin"

  # Preview CI (wait-ready, SHA-env apply) and the Flux ResourceSet factory are
  # a dev-cluster capability. Staging/prod overlays omit bjj-eire-preview and
  # Kyverno deny-ephemeral-envs rejects those namespaces.
  gha_pr_env_enabled = coalesce(var.gha_pr_env_enabled, var.environment == "dev")
}

module "cluster_identity" {
  source  = "Azure/avm-res-managedidentity-userassignedidentity/azurerm"
  version = "0.5.2"

  name                = "${var.cluster_identity_name_prefix}${var.environment}-${var.location_short_name}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  tags                = var.tags
  enable_telemetry    = var.identity_enable_telemetry

  role_assignments = {
    aks_vnet = {
      role_definition_id_or_name = var.cluster_identity_vnet_role_name
      scope                      = module.virtual_network.resource_id
    }
  }
}

# count rather than a moved-to-[0] block: staging/prod omit this role, and a
# `moved` `to` address that is not in config is an error. Dev will replace the
# unindexed resource with [0] once (new role definition id; the assignment
# below tracks it).
resource "azurerm_role_definition" "aks_pr_env_namespace_admin" {
  count = local.gha_pr_env_enabled ? 1 : 0

  name        = format(var.aks_pr_env_role_name_format, var.environment)
  scope       = module.aks.resource_id
  description = var.aks_pr_env_role_description

  permissions {
    actions          = var.aks_pr_env_role_actions
    not_actions      = var.aks_pr_env_role_not_actions
    data_actions     = var.aks_pr_env_role_data_actions
    not_data_actions = var.aks_pr_env_role_not_data_actions
  }

  assignable_scopes = [module.aks.resource_id]
}

module "workload_identities" {
  source = "./modules/workload-identities"

  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  tags                = var.tags
  enable_telemetry    = var.identity_enable_telemetry

  identities = merge({
    external_secrets = {
      name = "${var.external_secrets_identity_name_prefix}${var.environment}-${var.location_short_name}"
      federated_identity_credentials = {
        external_secrets = {
          audience = local.workload_identity_audience
          issuer   = module.aks.oidc_issuer_profile_issuer_url
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
          issuer   = module.aks.oidc_issuer_profile_issuer_url
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
          issuer   = module.aks.oidc_issuer_profile_issuer_url
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
          issuer   = module.aks.oidc_issuer_profile_issuer_url
          name     = local.fic_name_flux_source
          subject  = local.fic_subject_flux_source
        }
        flux_kustomize_controller = {
          audience = local.workload_identity_audience
          issuer   = module.aks.oidc_issuer_profile_issuer_url
          name     = local.fic_name_flux_kustomize
          subject  = local.fic_subject_flux_kustomize
        }
        flux_helm_controller = {
          audience = local.workload_identity_audience
          issuer   = module.aks.oidc_issuer_profile_issuer_url
          name     = local.fic_name_flux_helm
          subject  = local.fic_subject_flux_helm
        }
        flux_image_reflector_controller = {
          audience = local.workload_identity_audience
          issuer   = module.aks.oidc_issuer_profile_issuer_url
          name     = local.fic_name_flux_image_reflector
          subject  = local.fic_subject_flux_image_reflector
        }
        flux_image_automation_controller = {
          audience = local.workload_identity_audience
          issuer   = module.aks.oidc_issuer_profile_issuer_url
          name     = local.fic_name_flux_image_automation
          subject  = local.fic_subject_flux_image_automation
        }
        flux_notification_controller = {
          audience = local.workload_identity_audience
          issuer   = module.aks.oidc_issuer_profile_issuer_url
          name     = local.fic_name_flux_notification
          subject  = local.fic_subject_flux_notification
        }
      }
    }

    # Identity attached to the ARC runner ServiceAccount. The runner pod that
    # executes Playwright suites in the cluster reaches Entra as THIS identity
    # via Workload Identity, so no client secret is needed in CI.
    # The matching azuread_app_role_assignment below grants Tests.Invoke on
    # the bjjeire-api SP — same role the bjjeire-tests SP holds, granted to a
    # separate runtime identity.
    tests_runner = {
      name = "${var.tests_runner_identity_name_prefix}${var.environment}-${var.location_short_name}"
      federated_identity_credentials = {
        arc_runner = {
          audience = local.workload_identity_audience
          issuer   = module.aks.oidc_issuer_profile_issuer_url
          name     = local.fic_name_tests_runner
          subject  = local.fic_subject_tests_runner
        }
      }
    }
    },
    local.gha_pr_env_enabled ? {
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
          bjjeire_main = {
            audience = local.workload_identity_audience
            issuer   = local.github_oidc_issuer
            name     = local.fic_name_gha_prenv_bjjeire_main
            subject  = local.fic_subject_gha_prenv_bjjeire_main
          }
        }
        role_assignments = {
          (local.rk_aks_cluster_user) = {
            role_definition_id_or_name = var.gha_pr_env_aks_user_role_name
            scope                      = module.aks.resource_id
          }
          (local.rk_aks_pr_env_namespace_admin) = {
            role_definition_id_or_name = one(azurerm_role_definition.aks_pr_env_namespace_admin[*].role_definition_resource_id)
            scope                      = module.aks.resource_id
          }
        }
      }
    } : {},
    local.atest_history_enabled ? {
      gha_atest_history = {
        name = "${var.gha_atest_history_identity_name_prefix}${var.environment}-${var.location_short_name}"
        # TWO credentials, because two repositories run the analyze job and a
        # federated credential trusts exactly one subject.
        #
        # This was a real gap: the identity trusted bjjeire-tests alone, while
        # the job was wired into bjjeire's ci-main. The token exchange would
        # have failed with AADSTS70021 (no matching federated identity record)
        # and history would simply never have been written — a failure that
        # surfaces as flake verdicts reading "insufficient data" forever, which
        # is also what a correctly working new store says.
        #
        # Both stay pinned to refs/heads/main. Adding a repository here widens
        # who may WRITE the flake baseline, which is the one thing the split
        # with gha_pr_env exists to prevent.
        federated_identity_credentials = {
          # bjjeire-tests, plain subject format.
          main = {
            audience = local.workload_identity_audience
            issuer   = local.github_oidc_issuer
            name     = local.fic_name_gha_atest_history_main
            subject  = local.fic_subject_gha_prenv_tests_main
          }
          # bjjeire (the app repo), which has GitHub's IMMUTABLE subject format
          # enabled — hence org@owner_id/repo@repo_id rather than org/repo.
          # Reusing the local that gha_pr_env already proves works there.
          app_main = {
            audience = local.workload_identity_audience
            issuer   = local.github_oidc_issuer
            name     = local.fic_name_gha_atest_history_app
            subject  = local.fic_subject_gha_prenv_bjjeire_main
          }
        }
      }
  } : {})
}

resource "azuread_app_role_assignment" "tests_runner_invoke" {
  app_role_id         = var.api_app_roles.tests_invoke.id
  principal_object_id = module.workload_identities.principal_ids["tests_runner"]
  resource_object_id  = module.bjjeire_app_registrations.api_service_principal_object_id
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
  description = "Client ID of the GitHub Actions PR-env identity. Null when gha_pr_env_enabled is false (default off staging/prod). When github_manage_actions_oidc is true (default on dev), this stack writes it to AZURE_CLIENT_ID on gha_pr_env_app_repo and gha_pr_env_tests_repo so a UAMI recreate cannot leave CI on a deleted client ID."
  value       = try(module.workload_identities.client_ids["gha_pr_env"], null)
}

output "atest_history_identity_client_id" {
  description = "Client ID of the atest history writer identity. Set as the ATEST_HISTORY_CLIENT_ID repository variable in bjjeire-tests; the analyze job uses it for `azure/login` only on refs/heads/main. Distinct from gha_pr_env_identity_client_id, which is read-only on the history account."
  value       = try(module.workload_identities.client_ids["gha_atest_history"], null)
}

output "tests_runner_identity_client_id" {
  description = "Client ID of the ARC test-runner identity. Annotate the gha-runner-scale-set ServiceAccount with `azure.workload.identity/client-id: <this value>` so the runner pod authenticates to Entra via Workload Identity instead of a stored secret."
  value       = module.workload_identities.client_ids["tests_runner"]
}
