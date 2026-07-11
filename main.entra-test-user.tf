# Dedicated Entra user for the Playwright browser MSAL flow.
#
# Why a separate user (not your own):
#   - Real accounts get MFA, session timeouts, mailbox notifications when CI
#     signs in, and audit-log noise that masks real incidents.
#   - A real password sitting in CI secrets is a credential-management problem.
#   - This user is gated by playwright_test_user_enabled — off in prod by
#     default; opt-in per environment.
#
# Manual step that Terraform cannot safely automate:
#   The user must be excluded from any MFA-requiring Conditional Access
#   policy. Recommended: add this user to an existing "test-users-no-mfa"
#   security group that's listed under each CA policy's exclusions.
#   Automating CA policy creation here would risk lockout on misconfiguration.

locals {
  playwright_test_user_enabled  = var.playwright_test_user_enabled
  playwright_test_user_nickname = "${var.playwright_test_user_mail_nickname_prefix}-${var.environment}"
}

data "azuread_domains" "default" {
  count        = local.playwright_test_user_enabled ? 1 : 0
  only_default = true
}

resource "random_password" "playwright_test_user" {
  count = local.playwright_test_user_enabled ? 1 : 0

  length           = 32
  special          = true
  min_lower        = 2
  min_upper        = 2
  min_numeric      = 2
  min_special      = 2
  override_special = "!@#%^*-_+="

  lifecycle {
    ignore_changes = [
      length,
      special,
      min_lower,
      min_upper,
      min_numeric,
      min_special,
      override_special,
    ]
  }
}

resource "azuread_user" "playwright_test" {
  count = local.playwright_test_user_enabled ? 1 : 0

  user_principal_name = "${local.playwright_test_user_nickname}@${data.azuread_domains.default[0].domains[0].domain_name}"
  display_name        = "${var.playwright_test_user_display_name} (${var.environment})"
  mail_nickname       = local.playwright_test_user_nickname
  password            = random_password.playwright_test_user[0].result
  # CRITICAL for automation: do NOT require password change on first sign-in.
  # Playwright can't drive the change-password screen.
  force_password_change = false
  account_enabled       = true
}

output "bjjeire_pw_test_user_upn" {
  description = "UPN of the Playwright test user. Use as PW_TEST_USER in tests config. Null when playwright_test_user_enabled = false."
  value       = try(azuread_user.playwright_test[0].user_principal_name, null)
}

output "bjjeire_pw_test_user_password" {
  description = "Password of the Playwright test user. Use as PW_TEST_PASSWORD. Sensitive — also stored in KV as bjj-tests-pw-password."
  value       = try(random_password.playwright_test_user[0].result, null)
  sensitive   = true
}
