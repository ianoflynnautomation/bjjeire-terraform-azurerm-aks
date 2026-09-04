resource "random_password" "tunnel_secret" {
  count   = var.enabled ? 1 : 0
  length  = var.secret_length
  special = false
}

# Azure destroy leaves the Cloudflare tunnel behind. Creating the same name
# then returns 409 / code 1013. Delete inactive leftovers first; a healthy
# tunnel with live connectors is left alone.
resource "terraform_data" "clear_stale_tunnel" {
  count = var.enabled ? 1 : 0

  triggers_replace = {
    account_id = var.account_id
    name       = var.name
  }

  provisioner "local-exec" {
    command = "python3 -u '${path.module}/scripts/clear-stale-tunnel.py'"
    environment = {
      CF_API_TOKEN   = var.api_token
      CF_ACCOUNT_ID  = var.account_id
      CF_TUNNEL_NAME = var.name
    }
  }
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

  depends_on = [terraform_data.clear_stale_tunnel]
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
    # Most-specific hostnames first. cloudflared uses the first match, so
    # *.root_domain must sit after cluster_domain or dev.example.com is
    # sent to the Gateway's apex-wildcard listener (HTTP 404).
    ingress = concat(
      [
        for h in var.extra_hostnames : {
          hostname = h
          service  = var.origin_url
          origin_request = {
            no_tls_verify      = var.no_tls_verify
            http_host_header   = h
            origin_server_name = h
          }
        }
      ],
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
        for h in var.wildcard_hostnames : {
          hostname = h
          service  = var.origin_url
          origin_request = {
            no_tls_verify      = var.no_tls_verify
            origin_server_name = h
          }
        }
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

locals {
  tunnel_cname = var.enabled ? "${cloudflare_zero_trust_tunnel_cloudflared.this[0].id}.cfargotunnel.com" : ""
  dns_names = var.enabled ? concat(
    [var.cluster_domain, "*.${var.cluster_domain}"],
    var.extra_hostnames,
    var.wildcard_hostnames,
  ) : []
}

# Leftover A/AAAA (or CNAME to a previous tunnel / old cluster LB) at these
# names make Cloudflare reject the CNAME create with 81053. Delete them
# immediately before we create the records this module owns.
resource "terraform_data" "clear_conflicting_dns" {
  count = var.enabled ? 1 : 0

  triggers_replace = {
    names        = join("\n", local.dns_names)
    keep_content = local.tunnel_cname
    zone_id      = data.cloudflare_zone.this[0].zone_id
  }

  provisioner "local-exec" {
    command = "python3 -u '${path.module}/scripts/clear-conflicting-records.py'"
    environment = {
      CF_API_TOKEN    = var.api_token
      CF_ZONE_ID      = data.cloudflare_zone.this[0].zone_id
      CF_RECORD_NAMES = join("\n", local.dns_names)
      CF_KEEP_CONTENT = local.tunnel_cname
    }
  }
}

resource "cloudflare_dns_record" "tunnel" {
  count = var.enabled ? 1 : 0

  zone_id = data.cloudflare_zone.this[0].zone_id
  name    = var.cluster_domain
  content = local.tunnel_cname
  type    = var.dns_record_type
  proxied = var.dns_proxied
  ttl     = var.dns_ttl
  comment = var.dns_comment

  depends_on = [terraform_data.clear_conflicting_dns]
}

resource "cloudflare_dns_record" "tunnel_wildcard" {
  count = var.enabled ? 1 : 0

  zone_id = data.cloudflare_zone.this[0].zone_id
  name    = "*.${var.cluster_domain}"
  content = local.tunnel_cname
  type    = var.dns_record_type
  proxied = var.dns_proxied
  ttl     = var.dns_ttl
  comment = var.dns_wildcard_comment

  depends_on = [terraform_data.clear_conflicting_dns]
}

resource "cloudflare_dns_record" "tunnel_extra" {
  for_each = var.enabled ? toset(var.extra_hostnames) : []

  zone_id = data.cloudflare_zone.this[0].zone_id
  name    = each.value
  content = local.tunnel_cname
  type    = var.dns_record_type
  proxied = var.dns_proxied
  ttl     = var.dns_ttl
  comment = var.dns_extra_comment

  depends_on = [terraform_data.clear_conflicting_dns]
}

resource "cloudflare_dns_record" "tunnel_wildcard_extra" {
  for_each = var.enabled ? toset(var.wildcard_hostnames) : []

  zone_id = data.cloudflare_zone.this[0].zone_id
  name    = each.value
  content = local.tunnel_cname
  type    = var.dns_record_type
  proxied = var.dns_proxied
  ttl     = var.dns_ttl
  comment = var.dns_wildcard_comment

  depends_on = [terraform_data.clear_conflicting_dns]
}
