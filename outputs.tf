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

output "storage_atest_history_account_name" {
  description = "Storage account holding the atest run history. Set as the ATEST_HISTORY_ACCOUNT repository variable in bjjeire-java and bjjeire-tests; the analyze job gates every history step on it being non-empty, so leaving it unset simply disables persistence and the rest of the pipeline is unaffected."
  value       = one(module.storage_atest_history[*].name)
}

output "storage_atest_history_url" {
  description = <<-EOT
  The value atest's `--db` / ATEST_HISTORY_URL takes, ready to paste.

  Main-branch jobs use it as-is. Pull-request jobs append `?readonly=1`, which
  makes "a PR scores against trunk but never amends it" a declared mode rather
  than a 403 discovered once per shard file — the RBAC split in
  main.storage-atest.tf enforces it either way.
  EOT
  value = one([
    for container in values(var.storage_atest_containers) :
    "azblob://${var.storage_atest_account_name}/${container.name}"
    if local.atest_history_enabled
  ])
}

output "storage_images_primary_blob_endpoint" {
  description = "Primary blob endpoint for the images storage account. Used as the Cloudflare origin when surfacing images through the CDN."
  value       = nonsensitive(module.storage_images.resource.primary_blob_endpoint)
}
