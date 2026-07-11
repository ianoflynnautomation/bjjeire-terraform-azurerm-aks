output "id" {
  description = "Tunnel ID. Null when disabled."
  value       = try(cloudflare_zero_trust_tunnel_cloudflared.this[0].id, null)
}

output "name" {
  description = "Tunnel name. Null when disabled."
  value       = try(cloudflare_zero_trust_tunnel_cloudflared.this[0].name, null)
}

output "token" {
  description = "Cloudflared connector token. Stored in Key Vault by the caller. Null when disabled."
  value       = try(data.cloudflare_zero_trust_tunnel_cloudflared_token.this[0].token, null)
  sensitive   = true
}

output "zone_id" {
  description = "DNS zone ID resolved from var.zone_name. Null when disabled."
  value       = try(data.cloudflare_zone.this[0].zone_id, null)
}
