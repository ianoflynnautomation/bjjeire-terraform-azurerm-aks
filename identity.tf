
resource "azurerm_user_assigned_identity" "external_secrets_identity" {
  name                = "${var.aks_cluster_name}-external-secrets-identity"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  tags                = var.tags
}

resource "azurerm_user_assigned_identity" "observability_identity" {
  name                = "${var.aks_cluster_name}-observability-identity"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  tags                = var.tags
}

resource "azurerm_user_assigned_identity" "arc_identity" {
  name                = "${var.aks_cluster_name}-arc-identity"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  tags                = var.tags
}

resource "azurerm_user_assigned_identity" "flux_identity" {
  name                = "${var.aks_cluster_name}-flux-identity"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  tags                = var.tags
}


resource "azurerm_user_assigned_identity" "cluster_identity" {
  name                = "${var.aks_cluster_name}-control-plane-identity"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  tags                = var.tags
}


resource "azurerm_federated_identity_credential" "flux_source_controller" {
  name                = "${var.aks_cluster_name}-flux-source-controller-fed-id"
  resource_group_name = azurerm_resource_group.rg.name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = module.aks.oidc_issuer_url
  parent_id           = azurerm_user_assigned_identity.flux_identity.id
  subject             = "system:serviceaccount:flux-system:source-controller"
}

resource "azurerm_federated_identity_credential" "external_secrets" {
  name                = "${var.aks_cluster_name}-external-secrets-fed-id"
  resource_group_name = azurerm_resource_group.rg.name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = module.aks.oidc_issuer_url
  parent_id           = azurerm_user_assigned_identity.external_secrets_identity.id
  subject             = "system:serviceaccount:external-secrets:external-secrets"
}

resource "azurerm_federated_identity_credential" "observability" {
  name                = "${var.aks_cluster_name}-observability-fed-id"
  resource_group_name = azurerm_resource_group.rg.name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = module.aks.oidc_issuer_url
  parent_id           = azurerm_user_assigned_identity.observability_identity.id
  subject             = "system:serviceaccount:observability:observability"
}

resource "azurerm_federated_identity_credential" "arc" {
  name                = "${var.aks_cluster_name}-arc-fed-id"
  resource_group_name = azurerm_resource_group.rg.name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = module.aks.oidc_issuer_url
  parent_id           = azurerm_user_assigned_identity.arc_identity.id
  subject             = "system:serviceaccount:actions-runner-system:gha-runner-scale-set-controller"
}

resource "azurerm_role_assignment" "aks_vnet" {
  scope                = module.virtual_network.resource_id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.cluster_identity.principal_id
}
