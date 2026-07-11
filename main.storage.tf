module "storage_images" {
  source = "git::https://github.com/Azure/terraform-azurerm-avm-res-storage-storageaccount.git?ref=456bd88463bf63f08449644f60913c9523608b60" #v0.6.8

  name                            = var.storage_images_account_name
  resource_group_name             = azurerm_resource_group.rg.name
  location                        = azurerm_resource_group.rg.location
  account_tier                    = var.storage_images_account_tier
  account_replication_type        = var.storage_images_replication_type
  allow_nested_items_to_be_public = var.storage_images_allow_nested_items_to_be_public
  public_network_access_enabled   = var.storage_images_public_network_access_enabled
  https_traffic_only_enabled      = var.storage_images_https_traffic_only_enabled
  min_tls_version                 = var.storage_images_min_tls_version
  shared_access_key_enabled       = var.storage_images_shared_access_key_enabled
  enable_telemetry                = var.vnet_enable_telemetry

  blob_properties = {
    cors_rule = [
      {
        allowed_headers    = var.storage_images_blob_cors_allowed_headers
        allowed_methods    = var.storage_images_blob_cors_allowed_methods
        allowed_origins    = var.storage_images_cors_origins
        exposed_headers    = var.storage_images_blob_cors_exposed_headers
        max_age_in_seconds = var.storage_images_blob_cors_max_age_seconds
      }
    ]
  }

  containers = var.storage_images_containers

  role_assignments = {
    api_blob_reader = {
      role_definition_id_or_name = var.storage_images_role_definition_api
      principal_id               = module.workload_identities.principal_ids["api"]
    }
    seeder_blob_contributor = {
      role_definition_id_or_name = var.storage_images_role_definition_seeder
      principal_id               = module.workload_identities.principal_ids["seeder"]
    }
  }

  tags = var.tags
}

# ------------------------------------------------------------------------------
# Public image serving via Blob (currently disabled)
#
# Images are shipped inside the frontend container instead (BjjEire repo:
# src/bjjeire-app/Dockerfile copies tools/images/processed to /srv/images and
# Caddy serves them with immutable cache headers; Cloudflare caches at the edge).
#
# Switch to Blob-backed serving when the image set outgrows the container
# (~50-100MB) or non-developers need to upload. To enable, uncomment the
# overrides below (they replace the defaults in variables.storage.tf) and pass
# them through tfvars/CI, then:
#
#   1. Upload processed images (CI step or one-off, auth via the
#      seeder_blob_contributor role assignment above):
#        azcopy sync tools/images/processed \
#          "https://${var.storage_images_account_name}.blob.core.windows.net/images" \
#          --recursive
#
#   2. Route /images/* in the frontend Caddyfile to the blob endpoint
#      (reverse_proxy with the container prefix) so the relative /images/...
#      URLs in seed data keep working and Cloudflare keeps caching on the
#      app domain. Remove the COPY tools/images/processed line from the
#      frontend Dockerfile at the same time.
#
# storage_images_allow_nested_items_to_be_public = true
#
# storage_images_containers = {
#   images = {
#     name          = "images"
#     public_access = "Blob" # anonymous read per-blob; container listing stays disabled
#   }
# }
# ------------------------------------------------------------------------------
