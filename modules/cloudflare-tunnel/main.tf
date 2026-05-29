resource "random_password" "tunnel_secret" {
  count   = var.enabled ? 1 : 0
  length  = var.secret_length
  special = false
}

resource "cloudflare_zero_trust_tunnel_cloudflared" "this" {
  count = var.enabled ? 1 : 0

  account_id    = var.account_id
  name          = var.name
  tunnel_secret = base64encode(random_password.tunnel_secret[0].result)
  config_src    = var.config_src

  lifecycle {
    precondition {
      condition     = var.account_id != ""
      error_message = "var.account_id is empty. Either pass an explicit Cloudflare account ID OR grant the API token 'Account Settings: Read' so the caller's data.cloudflare_accounts lookup succeeds."
    }
  }
}

data "cloudflare_zero_trust_tunnel_cloudflared_token" "this" {
  count = var.enabled ? 1 : 0

  account_id = var.account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.this[0].id
}

resource "cloudflare_zero_trust_tunnel_cloudflared_config" "this" {
  count = var.enabled ? 1 : 0

  account_id = var.account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.this[0].id

  config = {
    ingress = concat(
      [
        {
          hostname = var.cluster_domain
          service  = var.origin_url
          origin_request = {
            no_tls_verify      = var.no_tls_verify
            http_host_header   = var.cluster_domain
            origin_server_name = var.cluster_domain
          }
        },
        {
          hostname = "*.${var.cluster_domain}"
          service  = var.origin_url
          origin_request = {
            no_tls_verify = var.no_tls_verify
            # SNI = the actual incoming subdomain. cloudflared substitutes the
            # request hostname; gateway picks the *.${cluster_domain} listener.
            origin_server_name = "*.${var.cluster_domain}"
          }
        },
      ],
      [
        {
          service = var.fallback_service
        }
      ],
    )
  }
}

data "cloudflare_zone" "this" {
  count = var.enabled ? 1 : 0

  filter = {
    name = var.zone_name
  }
}

resource "cloudflare_dns_record" "tunnel" {
  count = var.enabled ? 1 : 0

  zone_id = data.cloudflare_zone.this[0].zone_id
  name    = var.cluster_domain
  content = "${cloudflare_zero_trust_tunnel_cloudflared.this[0].id}.cfargotunnel.com"
  type    = var.dns_record_type
  proxied = var.dns_proxied
  ttl     = var.dns_ttl
  comment = var.dns_comment
}

resource "cloudflare_dns_record" "tunnel_wildcard" {
  count = var.enabled ? 1 : 0

  zone_id = data.cloudflare_zone.this[0].zone_id
  name    = "*.${var.cluster_domain}"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.this[0].id}.cfargotunnel.com"
  type    = var.dns_record_type
  proxied = var.dns_proxied
  ttl     = var.dns_ttl
  comment = var.dns_wildcard_comment
}
