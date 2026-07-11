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
