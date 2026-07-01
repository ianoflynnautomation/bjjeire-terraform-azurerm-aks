output "idp_id" {
  description = "Cloudflare Zero Trust IdP ID. Null when idp_enabled = false."
  value       = try(cloudflare_zero_trust_access_identity_provider.entra_id[0].id, null)
}

output "entra_app_client_id" {
  description = "Entra app registration client ID used by the IdP."
  value       = try(azuread_application.this[0].client_id, null)
}

output "access_app_id" {
  description = "Cloudflare Access application ID. Null when access is disabled."
  value       = try(cloudflare_zero_trust_access_application.this[0].id, null)
}

output "tests_service_token_client_id" {
  description = "Cloudflare Access service-token client ID (CF-Access-Client-Id header). Null when tests_service_token_name is empty."
  value       = try(cloudflare_zero_trust_access_service_token.tests[0].client_id, null)
}

output "tests_service_token_client_secret" {
  description = "Cloudflare Access service-token client secret (CF-Access-Client-Secret header). Sensitive. Null when tests_service_token_name is empty."
  value       = try(cloudflare_zero_trust_access_service_token.tests[0].client_secret, null)
  sensitive   = true
}
