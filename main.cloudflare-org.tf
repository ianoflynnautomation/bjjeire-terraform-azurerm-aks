resource "cloudflare_zero_trust_organization" "this" {
  count = var.cloudflare_manage_zone && var.cloudflare_team_name != "" && local.cloudflare_account_id != "" ? 1 : 0

  account_id                         = local.cloudflare_account_id
  auth_domain                        = "${var.cloudflare_team_name}${var.cloudflare_auth_domain_suffix}"
  name                               = var.cloudflare_team_name
  is_ui_read_only                    = var.cloudflare_org_is_ui_read_only
  user_seat_expiration_inactive_time = var.cloudflare_user_seat_expiration_inactive_time
}
