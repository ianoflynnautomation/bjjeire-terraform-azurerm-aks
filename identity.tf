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

}
