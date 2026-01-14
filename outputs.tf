output "system_subnet_id" {
  description = "The resource ID of the system subnet"
  value       = module.avm-res-network-virtualnetwork.subnets["system"].resource_id
}

output "workload_subnet_id" {
  description = "The resource ID of the workload subnet"
  value       = module.avm-res-network-virtualnetwork.subnets["workload"].resource_id
}

output "kv_uri" {
  description = "The URI of the vault for performing operations on keys and secrets"
  value       = module.avm-res-keyvault-vault.uri
}

output "workload_identity_client_id" {
  description = "The Client ID of the User Assigned Identity for the Actions Runner Controller."
  value       = azurerm_user_assigned_identity.cluster_identity.client_id
}

output "sops_key_id" {
  value = module.avm-res-keyvault-vault.keys["sops-encryption-key"].id
}
