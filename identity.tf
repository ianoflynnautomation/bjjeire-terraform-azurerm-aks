
resource "azurerm_user_assigned_identity" "external_secrets_identity" {
  name                = local.uami_name.extern_secrets
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  tags                = var.tags
}

resource "azurerm_user_assigned_identity" "observability_identity" {
  name                = local.uami_name.observability
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  tags                = var.tags
}

resource "azurerm_user_assigned_identity" "arc_identity" {
  name                = local.uami_name.arc
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  tags                = var.tags
}

resource "azurerm_user_assigned_identity" "flux_identity" {
  name                = local.uami_name.flux
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  tags                = var.tags
}

resource "azurerm_user_assigned_identity" "cluster_identity" {
  name                = local.uami_name.control_plane
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  tags                = var.tags
}

resource "azurerm_user_assigned_identity" "github_actions" {
  name                = local.uami_name.github
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  tags                = var.tags
}

resource "azurerm_federated_identity_credential" "github_oidc" {
  name                = "fic-github-${var.environment}"
  resource_group_name = azurerm_resource_group.rg.name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = "https://token.actions.githubusercontent.com"
  parent_id           = azurerm_user_assigned_identity.github_actions.id
  subject             = "repo:${var.github_org}/${var.github_repo}:environment:${var.environment}"
}

resource "azurerm_federated_identity_credential" "flux_source_controller" {
  name                = "fic-flux-source-controller"
  resource_group_name = azurerm_resource_group.rg.name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = module.aks.oidc_issuer_url
  parent_id           = azurerm_user_assigned_identity.flux_identity.id
  subject             = "system:serviceaccount:flux-system:source-controller"
}

resource "azurerm_federated_identity_credential" "external_secrets" {
  name                = "fic-external-secrets"
  resource_group_name = azurerm_resource_group.rg.name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = module.aks.oidc_issuer_url
  parent_id           = azurerm_user_assigned_identity.external_secrets_identity.id
  subject             = "system:serviceaccount:external-secrets:external-secrets"
}

resource "azurerm_federated_identity_credential" "observability" {
  name                = "fic-observability"
  resource_group_name = azurerm_resource_group.rg.name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = module.aks.oidc_issuer_url
  parent_id           = azurerm_user_assigned_identity.observability_identity.id
  subject             = "system:serviceaccount:observability:observability"
}

resource "azurerm_federated_identity_credential" "arc" {
  name                = "fic-arc-gha-runner"
  resource_group_name = azurerm_resource_group.rg.name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = module.aks.oidc_issuer_url
  parent_id           = azurerm_user_assigned_identity.arc_identity.id
  subject             = "system:serviceaccount:actions-runner-system:gha-runner-scale-set-controller"
}