data "cloudflare_zone" "this" {
  count = var.manage_zone ? 1 : 0

  filter = {
    name = var.zone_name
  }

  lifecycle {
    precondition {
      condition     = var.zone_name != ""
      error_message = "zone_name must be set when manage_zone = true."
    }
  }
}

locals {
  zone_id           = var.manage_zone ? data.cloudflare_zone.this[0].id : null
  zone_settings_eff = var.manage_zone ? var.zone_settings : {}

  hsts_value = join("; ", compact([
    "max-age=${var.hsts_max_age_seconds}",
    var.hsts_include_subdomains ? "includeSubDomains" : "",
    var.hsts_preload ? "preload" : "",
  ]))

  # Cloudflare Ruleset API constants — fixed by the API contract.
  ruleset_kind_zone              = "zone"
  ruleset_phase_waf              = "http_request_firewall_managed"
  ruleset_phase_cache            = "http_request_cache_settings"
  ruleset_phase_headers          = "http_response_headers_transform"
  ruleset_action_execute         = "execute"
  ruleset_action_cache_settings  = "set_cache_settings"
  ruleset_action_rewrite         = "rewrite"
  ruleset_match_all_expression   = "true"
  ruleset_edge_ttl_mode_override = "override_origin"
  ruleset_header_operation_set   = "set"

  # Security header names — protocol-fixed.
  hdr_strict_transport_security = "Strict-Transport-Security"
  hdr_x_content_type_options    = "X-Content-Type-Options"
  hdr_referrer_policy           = "Referrer-Policy"
  hdr_permissions_policy        = "Permissions-Policy"
  hdr_content_security_policy   = "Content-Security-Policy"
}

resource "cloudflare_zone_setting" "this" {
  for_each = local.zone_settings_eff

  zone_id    = local.zone_id
  setting_id = each.key
  value      = each.value
}

resource "cloudflare_ruleset" "waf_managed" {
  count = var.manage_zone && length(var.waf_managed_rulesets) > 0 ? 1 : 0

  zone_id     = local.zone_id
  name        = var.waf_ruleset_name
  description = var.waf_ruleset_description
  kind        = local.ruleset_kind_zone
  phase       = local.ruleset_phase_waf

  rules = [
    for k, v in var.waf_managed_rulesets : {
      action      = local.ruleset_action_execute
      description = v.description
      enabled     = v.enabled
      expression  = local.ruleset_match_all_expression
      action_parameters = {
        id = v.ruleset_id
      }
    }
  ]
}

resource "cloudflare_ruleset" "cache_rules" {
  count = var.manage_zone ? 1 : 0

  zone_id     = local.zone_id
  name        = var.cache_ruleset_name
  description = var.cache_ruleset_description
  kind        = local.ruleset_kind_zone
  phase       = local.ruleset_phase_cache

  rules = [
    {
      description = var.cache_rule_spa_shell_description
      enabled     = true
      action      = local.ruleset_action_cache_settings
      expression  = var.cache_rule_spa_shell_expression
      action_parameters = {
        cache = true
        edge_ttl = {
          mode    = local.ruleset_edge_ttl_mode_override
          default = var.spa_shell_edge_ttl_seconds
        }
        browser_ttl = {
          mode    = local.ruleset_edge_ttl_mode_override
          default = var.cache_rule_spa_shell_browser_ttl_seconds
        }
      }
    },
    {
      description = var.cache_rule_hashed_assets_description
      enabled     = true
      action      = local.ruleset_action_cache_settings
      expression  = var.cache_rule_hashed_assets_expression
      action_parameters = {
        cache = true
        edge_ttl = {
          mode    = local.ruleset_edge_ttl_mode_override
          default = var.static_asset_edge_ttl_seconds
        }
        browser_ttl = {
          mode    = local.ruleset_edge_ttl_mode_override
          default = var.static_asset_edge_ttl_seconds
        }
      }
    },
    {
      description = var.cache_rule_api_description
      enabled     = true
      action      = local.ruleset_action_cache_settings
      expression  = var.cache_rule_api_expression
      action_parameters = {
        cache = var.cache_rule_api_cache_enabled
      }
    },
  ]
}

resource "cloudflare_ruleset" "security_headers" {
  count = var.manage_zone ? 1 : 0

  zone_id     = local.zone_id
  name        = var.security_ruleset_name
  description = var.security_ruleset_description
  kind        = local.ruleset_kind_zone
  phase       = local.ruleset_phase_headers

  rules = [
    {
      description = var.security_rule_description
      enabled     = true
      action      = local.ruleset_action_rewrite
      expression  = local.ruleset_match_all_expression
      action_parameters = {
        headers = {
          (local.hdr_strict_transport_security) = {
            operation = local.ruleset_header_operation_set
            value     = local.hsts_value
          }
          (local.hdr_x_content_type_options) = {
            operation = local.ruleset_header_operation_set
            value     = var.security_header_x_content_type_options
          }
          (local.hdr_referrer_policy) = {
            operation = local.ruleset_header_operation_set
            value     = var.security_header_referrer_policy
          }
          (local.hdr_permissions_policy) = {
            operation = local.ruleset_header_operation_set
            value     = var.security_header_permissions_policy
          }
          (local.hdr_content_security_policy) = {
            operation = local.ruleset_header_operation_set
            value     = var.security_header_content_security_policy
          }
        }
      }
    },
  ]
}
