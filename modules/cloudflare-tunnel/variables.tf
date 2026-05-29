variable "enabled" {
  type        = bool
  description = "Master toggle. When false the module creates no resources."
  default     = true
  nullable    = false
}

variable "account_id" {
  type        = string
  description = "Cloudflare account ID. Must be non-empty when enabled = true."
  nullable    = false
}

variable "zone_name" {
  type        = string
  description = "DNS zone name to look up (e.g. example.com). The module reads its zone_id via data source."
  nullable    = false
}

variable "name" {
  type        = string
  description = "Tunnel name (caller pre-composes any prefix/suffix)."
  nullable    = false
}

variable "config_src" {
  type        = string
  description = "config_src for the cloudflared tunnel ('cloudflare' = remote-managed; 'local' = host-managed)."
  default     = "cloudflare"
  nullable    = false
}

variable "secret_length" {
  type        = number
  description = "Byte length of the random tunnel_secret. Cloudflare requires >= 32 bytes pre-base64."
  default     = 64
  nullable    = false

  validation {
    condition     = var.secret_length >= 32
    error_message = "secret_length must be at least 32 bytes."
  }
}

variable "origin_url" {
  type        = string
  description = "In-cluster origin URL the tunnel proxies to. Caller resolves any override-vs-default fallback."
  nullable    = false
}

variable "cluster_domain" {
  type        = string
  description = "Public domain served by the tunnel. The module creates both a record at this domain and a wildcard CNAME for *.<cluster_domain>."
  nullable    = false
}

variable "no_tls_verify" {
  type        = bool
  description = "Disable TLS verification on the tunnel → origin hop."
  default     = true
  nullable    = false
}

variable "fallback_service" {
  type        = string
  description = "Final cloudflared ingress entry (e.g. http_status:404)."
  default     = "http_status:404"
  nullable    = false
}

variable "dns_record_type" {
  type        = string
  description = "DNS record type for the tunnel hostname. CNAME because content is <tunnel-id>.cfargotunnel.com."
  default     = "CNAME"
  nullable    = false

  validation {
    condition     = contains(["CNAME", "A", "AAAA"], var.dns_record_type)
    error_message = "dns_record_type must be CNAME, A, or AAAA."
  }
}

variable "dns_proxied" {
  type        = bool
  description = "Whether the tunnel CNAMEs are proxied through Cloudflare."
  default     = true
  nullable    = false
}

variable "dns_ttl" {
  type        = number
  description = "DNS TTL for the tunnel records. 1 = automatic when proxied."
  default     = 1
  nullable    = false
}

variable "dns_comment" {
  type        = string
  description = "Comment on the apex tunnel DNS record (caller pre-composes any per-env suffix)."
  default     = "Managed by Terraform — Cloudflare Tunnel"
  nullable    = false
}

variable "dns_wildcard_comment" {
  type        = string
  description = "Comment on the wildcard tunnel DNS record."
  default     = "Managed by Terraform — Cloudflare Tunnel wildcard"
  nullable    = false
}
