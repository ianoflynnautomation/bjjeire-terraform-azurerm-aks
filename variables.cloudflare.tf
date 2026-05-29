variable "cloudflare_auth_domain_suffix" {
  type        = string
  default     = ".cloudflareaccess.com"
  description = "Cloudflare Zero Trust auth domain suffix. Concatenated with var.cloudflare_team_name to form the org auth_domain."
}

variable "cloudflare_org_is_ui_read_only" {
  type        = bool
  default     = false
  description = "Lock the Zero Trust dashboard to read-only. Set true after the org is stable to prevent UI drift."
}

variable "cloudflare_user_seat_expiration_inactive_time" {
  type        = string
  default     = "720h"
  description = "Inactive duration after which a Zero Trust user seat is released. Go duration string."
}

variable "cloudflare_idp_app_name_prefix" {
  type        = string
  default     = "cloudflare-zero-trust-"
  description = "Prefix for the Cloudflare Zero Trust IdP Entra app display name. Final name: <prefix><environment>."
}

variable "cloudflare_idp_app_sign_in_audience" {
  type        = string
  default     = "AzureADMyOrg"
  description = "sign_in_audience for the Cloudflare IdP Entra app. Single-tenant by default."
}

variable "cloudflare_idp_callback_path" {
  type        = string
  default     = "/cdn-cgi/access/callback"
  description = "Path component of the Cloudflare Access OIDC callback URL registered on the Entra app."
}

variable "cloudflare_idp_implicit_grant_access_token" {
  type        = bool
  default     = false
  description = "Allow implicit grant access tokens on the IdP Entra app. Should stay false for OIDC code flow."
}

variable "cloudflare_idp_implicit_grant_id_token" {
  type        = bool
  default     = false
  description = "Allow implicit grant id tokens on the IdP Entra app. Should stay false for OIDC code flow."
}

variable "cloudflare_idp_group_membership_claims" {
  type        = list(string)
  default     = ["SecurityGroup"]
  description = "group_membership_claims on the IdP Entra app. Restricts which group kinds appear in the groups claim."
}

variable "cloudflare_idp_id_token_claim_name" {
  type        = string
  default     = "groups"
  description = "optional_claims.id_token name added on the IdP Entra app."
}

variable "cloudflare_idp_access_token_claim_name" {
  type        = string
  default     = "groups"
  description = "optional_claims.access_token name added on the IdP Entra app."
}

variable "cloudflare_idp_password_display_name" {
  type        = string
  default     = "cloudflare-zero-trust"
  description = "display_name of the application password used as the IdP client secret."
}

variable "cloudflare_idp_delegated_permission_claims" {
  type        = list(string)
  default     = ["User.Read", "GroupMember.Read.All"]
  description = "Delegated Microsoft Graph permission claim values pre-consented for the Cloudflare IdP. Must match the resource_access scope IDs in locals."
}

variable "cloudflare_idp_name_format" {
  type        = string
  default     = "Entra ID (%s)"
  description = "Display-name format string for the Cloudflare Zero Trust IdP. %s is replaced with var.environment."
}

variable "cloudflare_idp_type" {
  type        = string
  default     = "azureAD"
  description = "Cloudflare Zero Trust IdP type — see Cloudflare docs for allowed values."
}

variable "cloudflare_idp_support_groups" {
  type        = bool
  default     = true
  description = "Tell Cloudflare to fetch group claims from the IdP. Required if Access policies match on Entra group OIDs."
}

variable "cloudflare_access_app_name_prefix" {
  type        = string
  default     = "bjjeire-"
  description = "Prefix for the Zero Trust Access application name. Final name: <prefix><environment>."
}

variable "cloudflare_access_app_type" {
  type        = string
  default     = "self_hosted"
  description = "Zero Trust Access application type. self_hosted gates origin traffic; saas/ssh/vnc available too."
}

variable "cloudflare_access_session_duration" {
  type        = string
  default     = "8h"
  description = "Access session lifetime. Go duration; users re-auth after this."
}

variable "cloudflare_access_app_launcher_visible" {
  type        = bool
  default     = true
  description = "Show the app in the Cloudflare Access launcher tile UI."
}

variable "cloudflare_access_auto_redirect_to_identity" {
  type        = bool
  default     = true
  description = "Skip the Cloudflare login chooser and redirect straight to the configured IdP."
}

variable "cloudflare_access_destination_type" {
  type        = string
  default     = "public"
  description = "type field for each Access app destination. public covers HTTP(S) hostnames."
}

variable "cloudflare_access_policy_name_suffix" {
  type        = string
  default     = "-internal-allow"
  description = "Suffix appended to <access_app_name_prefix><environment> to form the Access policy name."
}

variable "cloudflare_access_policy_decision" {
  type        = string
  default     = "allow"
  description = "Access policy decision. allow | block | non_identity | bypass."
}

variable "cloudflare_access_policy_precedence" {
  type        = number
  default     = 1
  description = "Precedence (rank) of the Access policy under the app. Lower = evaluated first."
}

variable "cloudflare_tunnel_name_prefix" {
  type        = string
  default     = "bjjeire-"
  description = "Prefix for the cloudflared tunnel name. Final name: <prefix><environment>."
}

variable "cloudflare_tunnel_secret_length" {
  type        = number
  default     = 64
  description = "Byte length of the random tunnel_secret. Cloudflare requires >= 32 bytes pre-base64."
}

variable "cloudflare_tunnel_config_src" {
  type        = string
  default     = "cloudflare"
  description = "config_src for the cloudflared tunnel. 'cloudflare' = remote-managed config (this stack writes it). 'local' = config lives next to the cloudflared binary on the host."
}

variable "cloudflare_tunnel_origin_default_url" {
  type        = string
  default     = "https://istio-ingressgateway-istio.istio-ingress.svc.cluster.local:443"
  description = "Default in-cluster origin URL the tunnel proxies to when var.tunnel_origin_service_url is empty. HTTPS so the http→https redirect HTTPRoute doesn't bounce every request."
}

variable "cloudflare_tunnel_no_tls_verify" {
  type        = bool
  default     = true
  description = "Disable TLS verification on the tunnel → origin hop. Required when cloudflared dials by cluster Service DNS but the cert SAN is the public FQDN."
}

variable "cloudflare_tunnel_fallback_service" {
  type        = string
  default     = "http_status:404"
  description = "Final cloudflared ingress entry. http_status:<n> short-circuits with a literal status when no earlier rule matches."
}

variable "cloudflare_tunnel_dns_record_type" {
  type        = string
  default     = "CNAME"
  description = "DNS record type for the tunnel hostname (and wildcard). CNAME because content is <tunnel-id>.cfargotunnel.com."
}

variable "cloudflare_tunnel_dns_proxied" {
  type        = bool
  default     = true
  description = "Whether the tunnel CNAMEs are proxied through Cloudflare (orange-cloud)."
}

variable "cloudflare_tunnel_dns_ttl" {
  type        = number
  default     = 1
  description = "DNS TTL for the tunnel records. 1 = automatic when proxied."
}

variable "cloudflare_tunnel_dns_comment_prefix" {
  type        = string
  default     = "Managed by Terraform — Cloudflare Tunnel for "
  description = "Comment prefix for the apex tunnel DNS record. var.environment is appended."
}

variable "cloudflare_tunnel_dns_wildcard_comment_prefix" {
  type        = string
  default     = "Managed by Terraform — Cloudflare Tunnel wildcard for "
  description = "Comment prefix for the wildcard tunnel DNS record. var.environment is appended."
}

variable "cloudflare_api_token" {
  type        = string
  description = "The cloudflare_api_token"
  sensitive   = true
  nullable    = false
}

variable "cloudflare_zone_name" {
  type        = string
  description = <<-EOT
  Public DNS zone managed in Cloudflare (e.g. "bjjeire.com"). Looked up by name
  to attach zone-level SSL settings, WAF rulesets, cache rules, and security
  response headers. Leave empty when cloudflare_manage_zone = false.
  EOT
  default     = ""
  nullable    = false

  validation {
    condition = (
      var.cloudflare_zone_name == "" || (
        length(split(".", var.cloudflare_zone_name)) >= 2 &&
        alltrue([for label in split(".", var.cloudflare_zone_name) : length(trimspace(label)) > 0])
      )
    )
    error_message = "cloudflare_zone_name must be empty or a valid DNS domain with two or more non-empty labels (e.g. \"bjjeire.com\")."
  }
}

variable "cloudflare_manage_zone" {
  type        = bool
  description = <<-EOT
  Toggle Cloudflare zone-level resources (SSL settings, WAF, cache rules,
  security headers) on/off. Zone state is shared across every cluster
  resolving under cloudflare_zone_name, so only ONE environment must own it.
  Recommended: true in prod, false in dev/stg.
  EOT
  default     = false
  nullable    = false
}

variable "cloudflare_zone_settings" {
  type        = map(string)
  description = <<-EOT
  Map of Cloudflare zone setting_id => value applied via for_each. See
  https://developers.cloudflare.com/api/operations/zone-settings-get-all-zone-settings
  for the catalogue. Defaults enforce: Full (Strict) origin TLS, TLS 1.3 on,
  HTTPS-only, HTTP/3 on, 0-RTT off (replay-safety for auth flows).
  EOT
  default = {
    ssl                      = "strict"
    min_tls_version          = "1.2"
    tls_1_3                  = "on"
    always_use_https         = "on"
    automatic_https_rewrites = "on"
    http3                    = "on"
    "0rtt"                   = "off"
    browser_check            = "on"
  }
  nullable = false
}

variable "cloudflare_waf_managed_rulesets" {
  type = map(object({
    ruleset_id  = string
    description = string
    enabled     = optional(bool, true)
  }))
  description = <<-EOT
  Cloudflare-published managed rulesets to deploy at zone scope.
  Ruleset IDs are stable; documented at
  https://developers.cloudflare.com/waf/managed-rules/reference/.
    * `cloudflare_managed`    - Cloudflare's curated baseline rules
    * `owasp_core`            - OWASP Core Rule Set (CRS)
    * `exposed_credentials`   - Blocks requests with known-compromised creds
  Set `enabled = false` on any entry to keep its config but disable it.
  EOT
  default = {
    cloudflare_managed = {
      ruleset_id  = "efb7b8c949ac4650a09736fc376e9aee"
      description = "Cloudflare Managed Ruleset"
    }
    owasp_core = {
      ruleset_id  = "4814384a9e5d4991b9815dcfc25d2f1f"
      description = "Cloudflare OWASP Core Ruleset"
    }
    exposed_credentials = {
      ruleset_id  = "c2e184081120413c86c3ab7e14069605"
      description = "Cloudflare Exposed Credentials Check"
    }
  }
  nullable = false
}

variable "cloudflare_hsts_max_age_seconds" {
  type        = number
  description = <<-EOT
  Strict-Transport-Security max-age in seconds. Ramp-up plan:
    * Initial:                   86400      (1 day, safe to roll back)
    * After 2 weeks clean HTTPS: 2592000    (30 days)
    * After 1 month clean HTTPS: 31536000   (1 year + add `preload`)
  EOT
  default     = 86400
  nullable    = false

  validation {
    condition     = var.cloudflare_hsts_max_age_seconds >= 0 && var.cloudflare_hsts_max_age_seconds <= 63072000
    error_message = "cloudflare_hsts_max_age_seconds must be between 0 and 63072000 (2 years)."
  }
}

variable "cloudflare_hsts_include_subdomains" {
  type        = bool
  description = "Add `includeSubDomains` to the HSTS header. Ensure every subdomain serves HTTPS before enabling."
  default     = true
  nullable    = false
}

variable "cloudflare_hsts_preload" {
  type        = bool
  description = "Add `preload` to the HSTS header. Only enable when you intend to submit to hstspreload.org — irreversible until the max-age expires."
  default     = false
  nullable    = false
}

variable "cloudflare_spa_shell_edge_ttl_seconds" {
  type        = number
  description = "Edge cache TTL for `/` and `/index.html` (the SPA shell). Short so frontend deploys take effect quickly."
  default     = 60
  nullable    = false

  validation {
    condition     = var.cloudflare_spa_shell_edge_ttl_seconds >= 0
    error_message = "cloudflare_spa_shell_edge_ttl_seconds must be non-negative."
  }
}

variable "cloudflare_static_asset_edge_ttl_seconds" {
  type        = number
  description = "Edge cache TTL for hash-fingerprinted assets under /assets/**. Long since filenames change every build."
  default     = 31536000
  nullable    = false

  validation {
    condition     = var.cloudflare_static_asset_edge_ttl_seconds >= 0
    error_message = "cloudflare_static_asset_edge_ttl_seconds must be non-negative."
  }
}

variable "cluster_domain" {
  type        = string
  default     = "cluster.local"
  description = <<DESCRIPTION
(Optional) The DNS domain name used within the Kubernetes cluster for service discovery.
Defaults to cluster.local.
DESCRIPTION
  nullable    = false

  validation {
    condition = (
      length(split(".", var.cluster_domain)) > 1
      && alltrue([for label in split(".", var.cluster_domain) : length(trimspace(label)) > 0])
    )
    error_message = "cluster_domain must contain at least two non-empty DNS labels, for example cluster.local or example.com."
  }
}

variable "enable_cloudflare_origin_lockdown" {
  type        = bool
  default     = true
  description = "When true, attach an NSG to the workload subnet that allows inbound 80/443 only from Cloudflare IPv4 ranges and denies all other Internet ingress on those ports. Outbound and intra-VNET traffic are unaffected."
}

variable "cloudflare_ipv4_ranges" {
  type        = list(string)
  default     = []
  description = "Cloudflare IPv4 CIDRs allowed inbound on 80/443 when enable_cloudflare_origin_lockdown is true. Empty list uses the built-in default snapshot (see locals in nsg.tf, sourced from https://www.cloudflare.com/ips-v4). Override only to pin a specific snapshot per env."
}

variable "cloudflare_tunnel_token" {
  type        = string
  default     = null
  sensitive   = true
  description = "Cloudflare Tunnel connector token issued in the Zero Trust dashboard (Networks → Tunnels). Stored in Key Vault as 'cloudflare-tunnel-token' and pulled by the in-cluster cloudflared deployment. Leave unset on envs that don't run a tunnel."
}

variable "cloudflare_account_id" {
  type        = string
  default     = ""
  description = "Cloudflare account ID. Leave empty to auto-resolve via data \"cloudflare_accounts\" (works when the API token is scoped to a single account)."
}

variable "cloudflare_team_name" {
  type        = string
  default     = ""
  description = "Cloudflare Zero Trust team subdomain — becomes <name>.cloudflareaccess.com. Account-wide; the env with cloudflare_manage_zone = true creates/owns the cloudflare_zero_trust_organization resource. Lower-case, hyphens allowed."
}

variable "enable_cloudflare_tunnel" {
  type        = bool
  default     = false
  description = "Provision a Cloudflare Tunnel (cloudflared) + ingress config + DNS CNAMEs + Entra IdP in Terraform. When true, var.cloudflare_tunnel_token is ignored and the token is sourced from the tunnel resource."
}

variable "tunnel_origin_service_url" {
  type        = string
  default     = ""
  description = "In-cluster origin the tunnel forwards traffic to. Defaults to http://istio-ingressgateway-istio.istio-ingress.svc.cluster.local:80. Override only if you change the ingress gateway service name/port."
}

variable "internal_access_group_object_id" {
  type        = string
  default     = ""
  description = "Entra ID security group Object ID whose members are allowed through Cloudflare Access. Either this OR internal_access_email_domain must be set on dev/staging."
}

variable "internal_access_email_domain" {
  type        = string
  default     = ""
  description = "Email domain (e.g. \"example.com\") accepted as an Allow rule on Cloudflare Access. Either this, internal_access_emails, or internal_access_group_object_id must be set on dev/staging."
}

variable "internal_access_emails" {
  type        = list(string)
  default     = []
  description = "Specific email addresses accepted as an Allow rule on Cloudflare Access. Use this for single-user dev clusters where setting a whole email_domain is too loose."
}
