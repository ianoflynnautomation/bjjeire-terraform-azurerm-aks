module "identity" {
  for_each = var.identities
  source   = "git::https://github.com/Azure/terraform-azurerm-avm-res-managedidentity-userassignedidentity.git?ref=f65ce0d66a73b2f78600954cef20e093f8c19851" #v0.5.2

  name                = each.value.name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
  enable_telemetry    = var.enable_telemetry

  federated_identity_credentials = each.value.federated_identity_credentials
  role_assignments               = each.value.role_assignments
}
