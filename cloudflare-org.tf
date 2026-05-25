# Cloudflare Zero Trust organization (account-wide singleton).
#
# The team domain (<name>.cloudflareaccess.com) is a Cloudflare account-level
# setting, not per-env. Only the prod env owns it (gated on cloudflare_manage_zone
# like the rest of the account-level Cloudflare resources). Dev/staging only
# READ the team name from var.cloudflare_team_name to build IdP redirect URIs.

resource "cloudflare_zero_trust_organization" "this" {
  count = var.cloudflare_manage_zone && var.cloudflare_team_name != "" && local.cloudflare_account_id != "" ? 1 : 0

  account_id                         = local.cloudflare_account_id
  auth_domain                        = "${var.cloudflare_team_name}${var.cloudflare_auth_domain_suffix}"
  name                               = var.cloudflare_team_name
  is_ui_read_only                    = var.cloudflare_org_is_ui_read_only
  user_seat_expiration_inactive_time = var.cloudflare_user_seat_expiration_inactive_time
}

locals {
  cloudflare_team_name = var.cloudflare_team_name
}
