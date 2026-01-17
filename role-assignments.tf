
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

resource "azurerm_role_assignment" "state_access" {
  scope                = "/subscriptions/${var.subscription_id}/resourceGroups/${var.state_resource_group_name}/providers/Microsoft.Storage/storageAccounts/${var.storage_account_name}"
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.github_actions.principal_id
}