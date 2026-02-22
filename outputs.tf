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
