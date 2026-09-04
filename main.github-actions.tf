locals {
  github_manage_actions_oidc = coalesce(var.github_manage_actions_oidc, var.environment == "dev")

  github_oidc_repos = local.github_manage_actions_oidc ? toset([
    var.gha_pr_env_app_repo,
    var.gha_pr_env_tests_repo,
  ]) : toset([])

  # Gates for the optional secret groups. These MUST be configuration-derived
  # booleans: the same flags select the secret names below, and github_actions_secret
  # takes its for_each keys from those names. Gating on a resource attribute
  # instead (client_id != null, user_principal_name != null) makes the condition
  # unknown until apply on a fresh create, so the key set is unknown and the plan
  # fails with "Invalid for_each argument".
  github_oidc_cf_access_enabled = local.github_manage_actions_oidc && module.cloudflare_access_idp.tests_service_token_enabled
  github_oidc_pw_user_enabled   = local.github_manage_actions_oidc && local.playwright_test_user_enabled

  github_oidc_secrets = local.github_manage_actions_oidc ? merge(
    {
      AZURE_CLIENT_ID           = module.workload_identities.client_ids["gha_pr_env"]
      AZURE_TENANT_ID           = data.azurerm_client_config.current.tenant_id
      AZURE_SUBSCRIPTION_ID     = var.subscription_id
      AZURE_TESTS_CLIENT_ID     = module.bjjeire_app_registrations.tests_client_id
      AZURE_TESTS_CLIENT_SECRET = module.bjjeire_app_registrations.tests_client_secret
      AZURE_API_SCOPE           = "${module.bjjeire_app_registrations.api_audience}/.default"
      AZURE_AUTHORITY           = "https://login.microsoftonline.com/${data.azurerm_client_config.current.tenant_id}"
    },
    local.github_oidc_cf_access_enabled ? {
      CF_ACCESS_CLIENT_ID     = module.cloudflare_access_idp.tests_service_token_client_id
      CF_ACCESS_CLIENT_SECRET = module.cloudflare_access_idp.tests_service_token_client_secret
    } : {},
    local.github_oidc_pw_user_enabled ? {
      PW_TEST_USER     = one(azuread_user.playwright_test[*].user_principal_name)
      PW_TEST_PASSWORD = one(random_password.playwright_test_user[*].result)
    } : {},
    {
      VITE_APP_MSAL_CLIENT_ID = module.bjjeire_app_registrations.spa_client_id
      VITE_APP_MSAL_AUTHORITY = "https://login.microsoftonline.com/${data.azurerm_client_config.current.tenant_id}"
      VITE_APP_MSAL_API_SCOPE = "${module.bjjeire_app_registrations.api_audience}/${var.api_oauth2_permission_scopes.access_as_user.value}"
    },
  ) : {}

  # Non-sensitive name list only — keys() of a map with secret values is itself sensitive
  # and cannot be used in for_each.
  github_oidc_secret_names = local.github_manage_actions_oidc ? toset(compact([
    "AZURE_CLIENT_ID",
    "AZURE_TENANT_ID",
    "AZURE_SUBSCRIPTION_ID",
    "AZURE_TESTS_CLIENT_ID",
    "AZURE_TESTS_CLIENT_SECRET",
    "AZURE_API_SCOPE",
    "AZURE_AUTHORITY",
    local.github_oidc_cf_access_enabled ? "CF_ACCESS_CLIENT_ID" : "",
    local.github_oidc_cf_access_enabled ? "CF_ACCESS_CLIENT_SECRET" : "",
    local.github_oidc_pw_user_enabled ? "PW_TEST_USER" : "",
    local.github_oidc_pw_user_enabled ? "PW_TEST_PASSWORD" : "",
  ])) : toset([])

  # SPA build-args — app repo only. Stale values bake a frontend that attaches
  # JWTs the new API cannot validate (catalog GETs then 401).
  github_oidc_secret_names_app = local.github_manage_actions_oidc ? toset([
    "VITE_APP_MSAL_CLIENT_ID",
    "VITE_APP_MSAL_AUTHORITY",
    "VITE_APP_MSAL_API_SCOPE",
  ]) : toset([])

  github_oidc_secret_pairs = merge(
    {
      for pair in setproduct(tolist(local.github_oidc_repos), tolist(local.github_oidc_secret_names)) :
      "${pair[0]}/${pair[1]}" => {
        repository = pair[0]
        name       = pair[1]
      }
    },
    local.github_manage_actions_oidc ? {
      for name in local.github_oidc_secret_names_app :
      "${var.gha_pr_env_app_repo}/${name}" => {
        repository = var.gha_pr_env_app_repo
        name       = name
      }
    } : {},
  )

  github_aks_variables = local.github_manage_actions_oidc ? {
    AKS_CLUSTER_NAME   = var.aks_cluster_name
    AKS_RESOURCE_GROUP = azurerm_resource_group.rg.name
    AKS_CLUSTER_DOMAIN = var.cluster_domain
    AKS_ROOT_DOMAIN    = var.cloudflare_root_domain
  } : {}
}

# Fail plan/apply if this stack cannot write Actions secrets. A 403 here is the
# GitHub App missing repository Secrets: Read and write — the same gap that
# left AZURE_CLIENT_ID / AZURE_TESTS_CLIENT_SECRET stale after teardown.
data "github_actions_public_key" "oidc" {
  for_each   = local.github_oidc_repos
  repository = each.value
}

resource "terraform_data" "github_oidc_required_on_dev" {
  lifecycle {
    precondition {
      condition     = var.environment != "dev" || local.github_manage_actions_oidc
      error_message = "github_manage_actions_oidc is false on dev. This apply would leave GitHub Actions on deleted UAMI/app secrets (AADSTS700016 / AADSTS7000215). Set github_manage_actions_oidc = true (or omit the variable) and re-apply with TF_VAR_github_token=$(gh auth token) until the bjjeire GitHub App can write repository Secrets and Variables."
    }
  }
}

resource "github_actions_secret" "oidc" {
  for_each = local.github_oidc_secret_pairs

  repository      = each.value.repository
  secret_name     = each.value.name
  plaintext_value = local.github_oidc_secrets[each.value.name]

  depends_on = [data.github_actions_public_key.oidc]
}

resource "github_actions_variable" "aks" {
  for_each = local.github_aks_variables

  repository    = var.gha_pr_env_app_repo
  variable_name = each.key
  value         = each.value

  depends_on = [data.github_actions_public_key.oidc]
}

# atest flake-history wiring, published to BOTH OIDC repos.
#
# The analyze job is wired into bjjeire's ci-main.yml, not bjjeire-tests, so
# publishing to the tests repo alone leaves `history-account` empty where the
# job actually runs. That does not fail: the workflow treats unset as "score
# this run against a throwaway local sqlite", so the analysis keeps reporting
# and every verdict reads "insufficient data" forever — indistinguishable from
# a new store still filling its window. It is the same trap main.identity.tf
# documents closing for the federated credential (which trusted bjjeire-tests
# while the job ran in bjjeire); closing it there and not here only moves where
# the wiring breaks.
#
# `github_oidc_repos` is already empty when github_manage_actions_oidc is off,
# so gating on atest_history_enabled alone is sufficient.
#
# Both are variables rather than secrets: a storage account name and a client ID
# are public identifiers, and a secret would only make them unreadable in logs
# where reading them is how you debug this. The caller may still pass them into
# the reusable workflow's `secrets:` block — that block names the input, not the
# source — but it must reference them as `vars.*`.
resource "github_actions_variable" "atest_history_account" {
  for_each = local.atest_history_enabled ? local.github_oidc_repos : toset([])

  repository    = each.value
  variable_name = "ATEST_HISTORY_ACCOUNT"
  value         = var.storage_atest_account_name
}

resource "github_actions_variable" "atest_history_client_id" {
  for_each = local.atest_history_enabled ? local.github_oidc_repos : toset([])

  repository    = each.value
  variable_name = "ATEST_HISTORY_CLIENT_ID"
  value         = module.workload_identities.client_ids["gha_atest_history"]
}
