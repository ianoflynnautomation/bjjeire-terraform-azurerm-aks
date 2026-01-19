
module "github_actions_identity" {
  source = "./modules/user-assigned-identity"

  name                = "uami-gha-${var.environment}-${var.location_short_name}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  tags                = var.tags

  federated_identity_credentials = {
    github_oidc = {
      audience = ["api://AzureADTokenExchange"]
      issuer   = "https://token.actions.githubusercontent.com"
      name     = "fic-github-${var.environment}"
      subject  = "repo:${var.github_org}/${var.github_repo}:environment:${var.environment}"
    }
  }

  role_assignments = {
    sub_contributor = {
      role_definition_id_or_name = "Contributor"
      scope                      = "/subscriptions/${var.subscription_id}"
    }
    state_access = {
      role_definition_id_or_name = "Storage Blob Data Contributor"
      scope                      = "/subscriptions/${var.subscription_id}/resourceGroups/${var.state_resource_group_name}/providers/Microsoft.Storage/storageAccounts/${var.storage_account_name}"
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

  depends_on = [module.virtual_network]
}

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

  depends_on = [module.aks]
}

module "observability_identity" {
  source = "./modules/user-assigned-identity"

  name                = "uami-obs-${var.environment}-${var.location_short_name}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  tags                = var.tags

  federated_identity_credentials = {
    observability = {
      audience = ["api://AzureADTokenExchange"]
      issuer   = module.aks.oidc_issuer_url
      name     = "fic-observability"
      subject  = "system:serviceaccount:observability:observability"
    }
  }

  depends_on = [module.aks]
}

module "arc_identity" {
  source = "./modules/user-assigned-identity"

  name                = "uami-arc-${var.environment}-${var.location_short_name}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  tags                = var.tags

  federated_identity_credentials = {
    arc = {
      audience = ["api://AzureADTokenExchange"]
      issuer   = module.aks.oidc_issuer_url
      name     = "fic-arc-gha-runner"
      subject  = "system:serviceaccount:actions-runner-system:gha-runner-scale-set-controller"
    }
  }

  depends_on = [module.aks]
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
  }

  depends_on = [module.aks]
}
