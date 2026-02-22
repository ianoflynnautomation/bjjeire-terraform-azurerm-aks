terraform {
  required_version = ">= 1.9.0, < 2.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.57.0"
    }
  }
}


locals {
  role_definition_resource_substring = "/providers/Microsoft.Authorization/roleDefinitions"
}

resource "azurerm_user_assigned_identity" "this" {
  location            = var.location
  name                = var.name
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_federated_identity_credential" "this" {
  for_each = var.federated_identity_credentials

  audience            = each.value.audience
  issuer              = each.value.issuer
  name                = each.value.name
  parent_id           = azurerm_user_assigned_identity.this.id
  resource_group_name = azurerm_user_assigned_identity.this.resource_group_name
  subject             = each.value.subject
}

resource "azurerm_role_assignment" "this" {
  for_each = var.role_assignments

  principal_id                           = azurerm_user_assigned_identity.this.principal_id
  scope                                  = each.value.scope
  condition                              = each.value.condition
  condition_version                      = each.value.condition_version
  delegated_managed_identity_resource_id = each.value.delegated_managed_identity_resource_id
  description                            = each.value.description
  role_definition_id                     = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? each.value.role_definition_id_or_name : null
  role_definition_name                   = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? null : each.value.role_definition_id_or_name
  skip_service_principal_aad_check       = each.value.skip_service_principal_aad_check
}
