output "kv_uri" {
  description = "Key Vault URI. Used for ad-hoc `az keyvault secret list/show --vault-name` operations."
  value       = module.key_vault.uri
}

output "sops_key_id" {
  description = "Key Vault encryption key for SOPS. Consumed by the SOPS CLI when encrypting/decrypting committed secrets."
  value       = module.key_vault.keys["sops-encryption-key"].id
}

output "oauth2_proxy_client_id" {
  description = "Entra app client ID for OAuth2 Proxy. Useful for verifying the bootstrap data.azuread_application.oauth2_proxy lookup resolves to the right app."
  value       = module.app_reg_oauth2_proxy.client_id
}

output "storage_images_primary_blob_endpoint" {
  description = "Primary blob endpoint for the images storage account. Used as the Cloudflare origin when surfacing images through the CDN."
  value       = nonsensitive(module.storage_images.resource.primary_blob_endpoint)
}
