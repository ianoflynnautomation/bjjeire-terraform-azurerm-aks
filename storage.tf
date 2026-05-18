module "storage_images" {
  source = "git::https://github.com/Azure/terraform-azurerm-avm-res-storage-storageaccount.git?ref=456bd88463bf63f08449644f60913c9523608b60" #v0.6.8

  name                            = var.storage_images_account_name
  resource_group_name             = azurerm_resource_group.rg.name
  location                        = azurerm_resource_group.rg.location
  account_tier                    = var.storage_images_account_settings.account_tier
  account_replication_type        = var.storage_images_replication_type
  allow_nested_items_to_be_public = var.storage_images_account_settings.allow_nested_items_to_be_public
  public_network_access_enabled   = var.storage_images_account_settings.public_network_access_enabled
  https_traffic_only_enabled      = var.storage_images_account_settings.https_traffic_only_enabled
  min_tls_version                 = var.storage_images_account_settings.min_tls_version
  shared_access_key_enabled       = var.storage_images_account_settings.shared_access_key_enabled
  enable_telemetry                = var.vnet_enable_telemetry

  blob_properties = {
    cors_rule = [
      {
        allowed_headers    = var.storage_images_blob_cors_rule.allowed_headers
        allowed_methods    = var.storage_images_blob_cors_rule.allowed_methods
        allowed_origins    = var.storage_images_cors_origins
        exposed_headers    = var.storage_images_blob_cors_rule.exposed_headers
        max_age_in_seconds = var.storage_images_blob_cors_rule.max_age_in_seconds
      }
    ]
  }

  containers = var.storage_images_containers

  role_assignments = {
    api_blob_reader = {
      role_definition_id_or_name = var.storage_images_role_definition_names.api
      principal_id               = module.api_identity.principal_id
    }
    seeder_blob_contributor = {
      role_definition_id_or_name = var.storage_images_role_definition_names.seeder
      principal_id               = module.seeder_identity.principal_id
    }
  }

  tags = var.tags
}
