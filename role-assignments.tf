
resource "azurerm_role_assignment" "sub_contributor" {
  scope                = "/subscriptions/${var.subscription_id}"
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.github_actions.principal_id
}

resource "azurerm_role_assignment" "aks_vnet" {
  scope                = module.virtual_network.resource_id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.cluster_identity.principal_id
}