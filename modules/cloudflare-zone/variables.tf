variable "manage_zone" {
  type        = bool
  description = "Toggle Cloudflare zone-level resources on/off. Zone state is shared across every cluster resolving under zone_name, so only ONE environment must own it."
  default     = false
  nullable    = false
}

variable "zone_name" {
  type        = string
  description = "Public DNS zone managed in Cloudflare (e.g. \"bjjeire.com\"). Looked up by name."
  default     = ""
  nullable    = false

  validation {
    condition = (
      var.zone_name == "" || (
        length(split(".", var.zone_name)) >= 2 &&
        alltrue([for label in split(".", var.zone_name) : length(trimspace(label)) > 0])
      )
    )
    error_message = "zone_name must be empty or a valid DNS domain with two or more non-empty labels."
  }
}

variable "zone_settings" {
  type        = map(string)
  description = "Map of Cloudflare zone setting_id => value applied via for_each."
  default     = {}
  nullable    = false
}

variable "waf_managed_rulesets" {
  type = map(object({
    ruleset_id  = string
    description = string
    enabled     = optional(bool, true)
  }))
  description = "Cloudflare-published managed rulesets to deploy at zone scope."
  default     = {}
  nullable    = false
}

variable "hsts_max_age_seconds" {
  type        = number
  description = "Strict-Transport-Security max-age in seconds."
  default     = 86400
  nullable    = false

  validation {
    condition     = var.hsts_max_age_seconds >= 0 && var.hsts_max_age_seconds <= 63072000
    error_message = "hsts_max_age_seconds must be between 0 and 63072000 (2 years)."
  }
}

variable "hsts_include_subdomains" {
  type        = bool
  description = "Add includeSubDomains to the HSTS header."
  default     = true
  nullable    = false
}

variable "hsts_preload" {
  type        = bool
  description = "Add preload to the HSTS header."
  default     = false
  nullable    = false
}

variable "spa_shell_edge_ttl_seconds" {
  type        = number
  description = "Edge cache TTL for the SPA shell."
  default     = 60
  nullable    = false
}

variable "static_asset_edge_ttl_seconds" {
  type        = number
  description = "Edge cache TTL for hash-fingerprinted assets under /assets/**."
  default     = 31536000
  nullable    = false
}

# ----- Ruleset metadata (names & descriptions) -----

variable "waf_ruleset_name" {
  type        = string
  default     = "Default WAF managed rulesets"
  description = "Display name for the cloudflare_ruleset that executes managed WAF rulesets."
}

variable "waf_ruleset_description" {
  type        = string
  default     = "Cloudflare-published managed rulesets executed at zone scope"
  description = "Description for the WAF managed ruleset wrapper."
}

variable "cache_ruleset_name" {
  type        = string
  default     = "SPA + API cache strategy"
  description = "Display name for the cache cloudflare_ruleset."
}

variable "cache_ruleset_description" {
  type        = string
  default     = "Long-cache hashed assets, short-cache SPA shell, never cache API"
  description = "Description for the cache ruleset."
}

variable "security_ruleset_name" {
  type        = string
  default     = "Security response headers"
  description = "Display name for the security-headers cloudflare_ruleset."
}

variable "security_ruleset_description" {
  type        = string
  default     = "HSTS + content-type / referrer / permissions / frame-ancestors hardening"
  description = "Description for the security-headers ruleset."
}

# ----- Cache rule descriptions & expressions -----

variable "cache_rule_spa_shell_description" {
  type        = string
  default     = "SPA shell — short edge cache, must revalidate"
  description = "Description on the SPA-shell cache rule."
}

variable "cache_rule_spa_shell_expression" {
  type        = string
  default     = "(http.request.uri.path eq \"/\") or (http.request.uri.path eq \"/index.html\")"
  description = "Cloudflare Ruleset expression that matches the SPA shell."
}

variable "cache_rule_spa_shell_browser_ttl_seconds" {
  type        = number
  default     = 0
  description = "browser_ttl.default applied to the SPA shell. 0 = never cache in browser (revalidate on every navigation)."
}

variable "cache_rule_hashed_assets_description" {
  type        = string
  default     = "Hash-fingerprinted assets — immutable"
  description = "Description on the hash-fingerprinted asset cache rule."
}

variable "cache_rule_hashed_assets_expression" {
  type        = string
  default     = "(http.request.uri.path matches \"^/assets/.+\\\\.[a-f0-9]{8,}\\\\.(js|css|woff2?|png|jpg|svg|webp|ico)$\")"
  description = "Cloudflare Ruleset expression that matches hash-fingerprinted static assets under /assets/**."
}

variable "cache_rule_api_description" {
  type        = string
  default     = "API endpoints — never cache by default"
  description = "Description on the API cache rule."
}

variable "cache_rule_api_expression" {
  type        = string
  default     = "(starts_with(http.request.uri.path, \"/api/\"))"
  description = "Cloudflare Ruleset expression that matches API routes."
}

variable "cache_rule_api_cache_enabled" {
  type        = bool
  default     = false
  description = "Whether API responses are cached. Default false to never cache."
}

# ----- Security-headers values -----

variable "security_rule_description" {
  type        = string
  default     = "Apply baseline security headers to every response"
  description = "Description on the security-headers rewrite rule."
}

variable "security_header_x_content_type_options" {
  type        = string
  default     = "nosniff"
  description = "Value for the X-Content-Type-Options response header."
}

variable "security_header_referrer_policy" {
  type        = string
  default     = "strict-origin-when-cross-origin"
  description = "Value for the Referrer-Policy response header."
}

variable "security_header_permissions_policy" {
  type        = string
  default     = "geolocation=(), microphone=(), camera=(), payment=()"
  description = "Value for the Permissions-Policy response header. Locks down browser feature APIs the site doesn't use."
}

variable "security_header_content_security_policy" {
  type        = string
  default     = "frame-ancestors 'none'"
  description = "Value for the Content-Security-Policy response header. Default blocks the site from being iframed."
}
