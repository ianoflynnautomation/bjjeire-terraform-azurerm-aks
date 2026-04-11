module "storage_images" {
  source = "git::https://github.com/Azure/terraform-azurerm-avm-res-storage-storageaccount.git?ref=456bd88463bf63f08449644f60913c9523608b60" #v0.6.8

  name                            = var.storage_images_account_name
  resource_group_name             = azurerm_resource_group.rg.name
  location                        = azurerm_resource_group.rg.location
  account_tier                    = "Standard"
  account_replication_type        = var.storage_images_replication_type
  allow_nested_items_to_be_public = false
  public_network_access_enabled   = true
  https_traffic_only_enabled      = true
  min_tls_version                 = "TLS1_2"
  shared_access_key_enabled       = false
  enable_telemetry                = var.vnet_enable_telemetry

  blob_properties = {
    cors_rule = [
      {
        allowed_headers    = ["*"]
        allowed_methods    = ["GET", "HEAD"]
        allowed_origins    = var.storage_images_cors_origins
        exposed_headers    = ["ETag", "Content-Length", "Content-Type"]
        max_age_in_seconds = 86400
      }
    ]
  }

  containers = {
    images = {
      name          = "images"
      public_access = "None"
    }
  }

  # Grant the API pod identity Storage Blob Data Contributor
  # (Contributor needed for upload; Reader would suffice for readonly display only)
  role_assignments = {
    api_blob_contributor = {
      role_definition_id_or_name = "Storage Blob Data Contributor"
      principal_id               = module.api_identity.principal_id
    }
  }

  tags = var.tags
}
