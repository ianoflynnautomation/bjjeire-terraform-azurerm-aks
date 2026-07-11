module "identity" {
  for_each = var.identities
  source   = "git::https://github.com/Azure/terraform-azurerm-avm-res-managedidentity-userassignedidentity.git?ref=1aaccd013b15a6eb754749a6a421d856e64e01a0" #v0.5.1

  name                = each.value.name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
  enable_telemetry    = var.enable_telemetry

  federated_identity_credentials = each.value.federated_identity_credentials
  role_assignments               = each.value.role_assignments
}
