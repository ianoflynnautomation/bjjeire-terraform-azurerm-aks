data "azurerm_client_config" "current" {}

module "rg" {
  source  = "Azure/avm-res-resources-resourcegroup/azurerm"
  version = "0.4.0"

  name             = var.resource_group_name
  location         = var.location
  tags             = var.tags
  enable_telemetry = var.identity_enable_telemetry
}
