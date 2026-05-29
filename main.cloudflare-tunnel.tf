module "cloudflare_tunnel" {
  source = "./modules/cloudflare-tunnel"

  enabled    = var.enable_cloudflare_tunnel
  account_id = local.cloudflare_account_id
  zone_name  = var.cloudflare_zone_name

  name          = "${var.cloudflare_tunnel_name_prefix}${var.environment}"
  config_src    = var.cloudflare_tunnel_config_src
  secret_length = var.cloudflare_tunnel_secret_length

  origin_url       = var.tunnel_origin_service_url != "" ? var.tunnel_origin_service_url : var.cloudflare_tunnel_origin_default_url
  cluster_domain   = var.cluster_domain
  no_tls_verify    = var.cloudflare_tunnel_no_tls_verify
  fallback_service = var.cloudflare_tunnel_fallback_service

  dns_record_type      = var.cloudflare_tunnel_dns_record_type
  dns_proxied          = var.cloudflare_tunnel_dns_proxied
  dns_ttl              = var.cloudflare_tunnel_dns_ttl
  dns_comment          = "${var.cloudflare_tunnel_dns_comment_prefix}${var.environment}"
  dns_wildcard_comment = "${var.cloudflare_tunnel_dns_wildcard_comment_prefix}${var.environment}"
}

moved {
  from = random_password.tunnel_secret
  to   = module.cloudflare_tunnel.random_password.tunnel_secret
}

moved {
  from = cloudflare_zero_trust_tunnel_cloudflared.this
  to   = module.cloudflare_tunnel.cloudflare_zero_trust_tunnel_cloudflared.this
}

moved {
  from = cloudflare_zero_trust_tunnel_cloudflared_config.this
  to   = module.cloudflare_tunnel.cloudflare_zero_trust_tunnel_cloudflared_config.this
}

moved {
  from = cloudflare_dns_record.tunnel
  to   = module.cloudflare_tunnel.cloudflare_dns_record.tunnel
}

moved {
  from = cloudflare_dns_record.tunnel_wildcard
  to   = module.cloudflare_tunnel.cloudflare_dns_record.tunnel_wildcard
}
