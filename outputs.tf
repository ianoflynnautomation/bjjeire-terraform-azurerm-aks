output "system_subnet_id" {
  description = "The resource ID of the system subnet"
  value       = module.virtual_network.subnets["system"].resource_id
}

output "workload_subnet_id" {
  description = "The resource ID of the workload subnet"
  value       = module.virtual_network.subnets["workload"].resource_id
}

output "kv_uri" {
  description = "The URI of the vault for performing operations on keys and secrets"
  value       = module.key_vault.uri
}

output "sops_key_id" {
  description = "SOPS key vault encryption key"
  value       = module.key_vault.keys["sops-encryption-key"].id
}

output "oauth2_proxy_client_id" {
  description = "The Azure Entra application client ID for OAuth2 Proxy"
  value       = azuread_application.oauth2_proxy.client_id
}

output "oauth2_proxy_application_id" {
  description = "The Azure Entra application object ID for OAuth2 Proxy"
  value       = azuread_application.oauth2_proxy.id
}

output "storage_images_primary_blob_endpoint" {
  description = "Primary blob endpoint for the images storage account — use as Cloudflare origin"
  value       = module.storage_images.resource.primary_blob_endpoint
}

output "storage_images_account_name" {
  description = "Name of the images storage account"
  value       = module.storage_images.resource.name
}

output "api_identity_client_id" {
  description = "Client ID of the API workload identity — annotate the bjjeire-api ServiceAccount with this value"
  value       = module.api_identity.client_id
}
