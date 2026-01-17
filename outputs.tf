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
