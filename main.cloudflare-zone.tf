module "cloudflare_zone" {
  source = "./modules/cloudflare-zone"

  manage_zone          = var.cloudflare_manage_zone
  zone_name            = var.cloudflare_zone_name
  zone_settings        = var.cloudflare_zone_settings
  waf_managed_rulesets = var.cloudflare_waf_managed_rulesets

  hsts_max_age_seconds    = var.cloudflare_hsts_max_age_seconds
  hsts_include_subdomains = var.cloudflare_hsts_include_subdomains
  hsts_preload            = var.cloudflare_hsts_preload

  spa_shell_edge_ttl_seconds    = var.cloudflare_spa_shell_edge_ttl_seconds
  static_asset_edge_ttl_seconds = var.cloudflare_static_asset_edge_ttl_seconds
}

moved {
  from = cloudflare_zone_setting.this
  to   = module.cloudflare_zone.cloudflare_zone_setting.this
}

moved {
  from = cloudflare_ruleset.waf_managed
  to   = module.cloudflare_zone.cloudflare_ruleset.waf_managed
}

moved {
  from = cloudflare_ruleset.cache_rules
  to   = module.cloudflare_zone.cloudflare_ruleset.cache_rules
}

moved {
  from = cloudflare_ruleset.security_headers
  to   = module.cloudflare_zone.cloudflare_ruleset.security_headers
}
