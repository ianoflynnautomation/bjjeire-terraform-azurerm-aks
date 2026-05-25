# Cloudflare Tunnel — origin-less ingress for the cluster.
#
# Creates the tunnel, its config (ingress rules → istio-ingress), and the
# single DNS CNAME pointing var.cluster_domain at the tunnel. The tunnel
# token is captured and stored in Key Vault as 'cloudflare-tunnel-token',
# which the in-cluster cloudflared deployment reads via external-secrets.
#
# DNS exception: this is the ONLY cloudflare_dns_record allowed in this
# repo (see cloudflare.tf header). The tunnel CNAME cannot be reconciled
# by external-dns because it points to <tunnel-id>.cfargotunnel.com, not
# to a Kubernetes Service.

data "cloudflare_accounts" "this" {
  count = var.enable_cloudflare_tunnel && var.cloudflare_account_id == "" ? 1 : 0
}

locals {
  accounts_lookup = try(data.cloudflare_accounts.this[0].result, [])
  cloudflare_account_id = (
    var.cloudflare_account_id != ""
    ? var.cloudflare_account_id
    : (length(local.accounts_lookup) > 0 ? local.accounts_lookup[0].id : "")
  )
  tunnel_origin = var.tunnel_origin_service_url != "" ? var.tunnel_origin_service_url : var.cloudflare_tunnel_origin_default_url
}

resource "random_password" "tunnel_secret" {
  count   = var.enable_cloudflare_tunnel ? 1 : 0
  length  = var.cloudflare_tunnel_secret_length
  special = false
}

resource "cloudflare_zero_trust_tunnel_cloudflared" "this" {
  count = var.enable_cloudflare_tunnel ? 1 : 0

  account_id    = local.cloudflare_account_id
  name          = "${var.cloudflare_tunnel_name_prefix}${var.environment}"
  tunnel_secret = base64encode(random_password.tunnel_secret[0].result)
  config_src    = var.cloudflare_tunnel_config_src

  lifecycle {
    precondition {
      condition     = local.cloudflare_account_id != ""
      error_message = "Could not resolve a Cloudflare account ID. Either set var.cloudflare_account_id explicitly in tfvars, OR grant the API token 'Account Settings: Read' so the data.cloudflare_accounts lookup succeeds."
    }
  }
}

data "cloudflare_zero_trust_tunnel_cloudflared_token" "this" {
  count = var.enable_cloudflare_tunnel ? 1 : 0

  account_id = local.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.this[0].id
}

resource "cloudflare_zero_trust_tunnel_cloudflared_config" "this" {
  count = var.enable_cloudflare_tunnel ? 1 : 0

  account_id = local.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.this[0].id

  config = {
    ingress = concat(
      [
        {
          hostname = var.cluster_domain
          service  = local.tunnel_origin
          origin_request = {
            no_tls_verify      = var.cloudflare_tunnel_no_tls_verify
            http_host_header   = var.cluster_domain
            origin_server_name = var.cluster_domain
          }
        },
        {
          hostname = "*.${var.cluster_domain}"
          service  = local.tunnel_origin
          origin_request = {
            no_tls_verify = var.cloudflare_tunnel_no_tls_verify
            # SNI = the actual incoming subdomain. cloudflared substitutes the
            # request hostname; gateway picks the *.${cluster_domain} listener.
            origin_server_name = "*.${var.cluster_domain}"
          }
        },
      ],
      [
        {
          service = var.cloudflare_tunnel_fallback_service
        }
      ],
    )
  }
}

data "cloudflare_zone" "this" {
  count = var.enable_cloudflare_tunnel ? 1 : 0

  filter = {
    name = var.cloudflare_zone_name
  }
}

resource "cloudflare_dns_record" "tunnel" {
  count = var.enable_cloudflare_tunnel ? 1 : 0

  zone_id = data.cloudflare_zone.this[0].zone_id
  name    = var.cluster_domain
  content = "${cloudflare_zero_trust_tunnel_cloudflared.this[0].id}.cfargotunnel.com"
  type    = var.cloudflare_tunnel_dns_record_type
  proxied = var.cloudflare_tunnel_dns_proxied
  ttl     = var.cloudflare_tunnel_dns_ttl
  comment = "${var.cloudflare_tunnel_dns_comment_prefix}${var.environment}"
}

resource "cloudflare_dns_record" "tunnel_wildcard" {
  count = var.enable_cloudflare_tunnel ? 1 : 0

  zone_id = data.cloudflare_zone.this[0].zone_id
  name    = "*.${var.cluster_domain}"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.this[0].id}.cfargotunnel.com"
  type    = var.cloudflare_tunnel_dns_record_type
  proxied = var.cloudflare_tunnel_dns_proxied
  ttl     = var.cloudflare_tunnel_dns_ttl
  comment = "${var.cloudflare_tunnel_dns_wildcard_comment_prefix}${var.environment}"
}
