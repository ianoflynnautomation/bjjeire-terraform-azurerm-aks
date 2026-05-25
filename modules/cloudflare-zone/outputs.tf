output "zone_id" {
  description = "ID of the managed Cloudflare zone. Null when manage_zone = false."
  value       = local.zone_id
}
