module "external_secrets_identity" {
  source = "./modules/user-assigned-identity"

  name                = "uami-extsecrets-${var.environment}-${var.location_short_name}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  tags                = var.tags

  federated_identity_credentials = {
    external_secrets = {
      audience = ["api://AzureADTokenExchange"]
      issuer   = module.aks.oidc_issuer_url
      name     = "fic-external-secrets"
      subject  = "system:serviceaccount:external-secrets:external-secrets"
    }
  }
}

module "cluster_identity" {
  source = "./modules/user-assigned-identity"

  name                = "uami-cp-${var.environment}-${var.location_short_name}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  tags                = var.tags

  role_assignments = {
    aks_vnet = {
      role_definition_id_or_name = "Network Contributor"
      scope                      = module.virtual_network.resource_id
    }
  }
}

module "api_identity" {
  source = "./modules/user-assigned-identity"

  name                = "uami-bjjeire-api-${var.environment}-${var.location_short_name}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  tags                = var.tags

  federated_identity_credentials = {
    bjjeire_api = {
      audience = ["api://AzureADTokenExchange"]
      issuer   = module.aks.oidc_issuer_url
      name     = "fic-bjjeire-api"
      subject  = "system:serviceaccount:bjjeire:bjjeire-api"
    }
  }
}

module "seeder_identity" {
  source = "./modules/user-assigned-identity"

  name                = "uami-bjjeire-seeder-${var.environment}-${var.location_short_name}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  tags                = var.tags

  federated_identity_credentials = {
    bjjeire_seeder = {
      audience = ["api://AzureADTokenExchange"]
      issuer   = module.aks.oidc_issuer_url
      name     = "fic-bjjeire-seeder"
      subject  = "system:serviceaccount:bjjeire:bjjeire-seeder"
    }
  }
}

output "bjjeire_api_identity_client_id" {
  description = "Client ID of the bjjeire-api workload identity. Used by the api ServiceAccount annotation."
  value       = module.api_identity.client_id
}

output "bjjeire_seeder_identity_client_id" {
  description = "Client ID of the bjjeire-seeder workload identity. Used by the seeder Job ServiceAccount annotation."
  value       = module.seeder_identity.client_id
}

module "flux_identity" {
  source = "./modules/user-assigned-identity"

  name                = "uami-flux-${var.environment}-${var.location_short_name}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  tags                = var.tags

  federated_identity_credentials = {
    flux_source_controller = {
      audience = ["api://AzureADTokenExchange"]
      issuer   = module.aks.oidc_issuer_url
      name     = "fic-flux-source-controller"
      subject  = "system:serviceaccount:flux-system:source-controller"
    }
    flux_kustomize_controller = {
      audience = ["api://AzureADTokenExchange"]
      issuer   = module.aks.oidc_issuer_url
      name     = "fic-flux-kustomize-controller"
      subject  = "system:serviceaccount:flux-system:kustomize-controller"
    }
    flux_helm_controller = {
      audience = ["api://AzureADTokenExchange"]
      issuer   = module.aks.oidc_issuer_url
      name     = "fic-flux-helm-controller"
      subject  = "system:serviceaccount:flux-system:helm-controller"
    }
    flux_image_reflector_controller = {
      audience = ["api://AzureADTokenExchange"]
      issuer   = module.aks.oidc_issuer_url
      name     = "fic-flux-image-reflector"
      subject  = "system:serviceaccount:flux-system:image-reflector-controller"
    }
    flux_image_automation_controller = {
      audience = ["api://AzureADTokenExchange"]
      issuer   = module.aks.oidc_issuer_url
      name     = "fic-flux-image-automation"
      subject  = "system:serviceaccount:flux-system:image-automation-controller"
    }
    flux_notification_controller = {
      audience = ["api://AzureADTokenExchange"]
      issuer   = module.aks.oidc_issuer_url
      name     = "fic-flux-notification-controller"
      subject  = "system:serviceaccount:flux-system:notification-controller"
    }
  }

}

module "gha_pr_env_identity" {
  source = "./modules/user-assigned-identity"

  name                = "uami-gha-prenv-${var.environment}-${var.location_short_name}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  tags                = var.tags

  federated_identity_credentials = {
    pull_request = {
      audience = ["api://AzureADTokenExchange"]
      issuer   = "https://token.actions.githubusercontent.com"
      name     = "fic-gha-prenv-pull-request"
      subject  = "repo:${var.github_org}/bjjeire-tests:pull_request"
    }
    main = {
      audience = ["api://AzureADTokenExchange"]
      issuer   = "https://token.actions.githubusercontent.com"
      name     = "fic-gha-prenv-main"
      subject  = "repo:${var.github_org}/bjjeire-tests:ref:refs/heads/main"
    }
    bjjeire_pull_request = {
      audience = ["api://AzureADTokenExchange"]
      issuer   = "https://token.actions.githubusercontent.com"
      name     = "fic-gha-prenv-bjjeire-pull-request"
      subject  = "repo:${var.github_org}/${var.github_repo}:pull_request"
    }
  }

  role_assignments = {
    aks_cluster_user = {
      role_definition_id_or_name = "Azure Kubernetes Service Cluster User Role"
      scope                      = module.aks.aks_id
    }
    aks_pr_env_namespace_admin = {
      role_definition_id_or_name = azurerm_role_definition.aks_pr_env_namespace_admin.role_definition_resource_id
      scope                      = module.aks.aks_id
    }
  }
}

resource "azurerm_role_definition" "aks_pr_env_namespace_admin" {
  name        = "AKS PR-env Namespace Admin (${var.environment})"
  scope       = module.aks.aks_id
  description = "Allows the GitHub Actions pr-env workflow to manage ephemeral PR namespaces in AKS. Permits namespace + most namespaced-resource CRUD via Azure RBAC for Kubernetes, but cannot mutate cluster RBAC, node pools, or AKS itself."

  permissions {
    actions = [
      "Microsoft.ContainerService/managedClusters/read",
      "Microsoft.ContainerService/managedClusters/listClusterUserCredential/action",
    ]

    not_actions = [
      "Microsoft.ContainerService/managedClusters/listClusterAdminCredential/action",
      "Microsoft.ContainerService/managedClusters/runCommand/action",
    ]

    data_actions = [
      "Microsoft.ContainerService/managedClusters/namespaces/read",
      "Microsoft.ContainerService/managedClusters/namespaces/write",
      "Microsoft.ContainerService/managedClusters/namespaces/delete",
    ]
  }

  assignable_scopes = [module.aks.aks_id]
}

output "gha_pr_env_identity_client_id" {
  description = "Client ID of the GitHub Actions PR-env identity. Set as AZURE_CLIENT_ID secret in bjjeire-tests + BjjEire repos for the pr-env.yml workflow."
  value       = module.gha_pr_env_identity.client_id
}
