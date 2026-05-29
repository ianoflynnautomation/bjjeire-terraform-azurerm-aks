# Shared Cloudflare root-level resolution consumed by main.cloudflare-tunnel.tf,
# main.cloudflare-idp.tf, main.cloudflare-access.tf and main.cloudflare-org.tf.
# The account_id fallback lookup requires the API token to hold
# "Account Settings: Read"; set var.cloudflare_account_id explicitly in tfvars
# to skip the lookup entirely.

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
}
