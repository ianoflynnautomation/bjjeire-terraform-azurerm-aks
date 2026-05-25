module "identity" {
  for_each = var.identities
  source   = "../user-assigned-identity"

  name                = each.value.name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  federated_identity_credentials = each.value.federated_identity_credentials
  role_assignments               = each.value.role_assignments
}
