# GitHub Environment + Azure directory role for THIS repository's plan/apply CI.
#
# Each environment's apply (dev / staging / prod) creates the GitHub Environment
# of the same name, writes ARM_* / state account variables, and federates the
# gha_terraform UAMI to `environment:<name>` (and refs/heads/main).
#
# First apply is still from a laptop. After it, CI authenticates with OIDC.
# TF_VAR_* secrets are NOT written here — set them once in the GitHub UI
# (they are long-lived tokens, not outputs of this stack).

data "azurerm_storage_account" "state" {
  name                = var.storage_account_name
  resource_group_name = var.state_resource_group_name
}

data "github_user" "environment_reviewer" {
  for_each = toset(var.github_environment_reviewer_logins)
  username = each.value
}

resource "github_repository_environment" "terraform" {
  repository  = var.github_repo
  environment = var.environment

  # Dev is used by pull_request plan jobs, so it must not be restricted to
  # protected branches. Staging/prod apply only from main.
  dynamic "deployment_branch_policy" {
    for_each = var.environment == "dev" ? [] : [1]
    content {
      protected_branches     = true
      custom_branch_policies = false
    }
  }

  dynamic "reviewers" {
    for_each = var.environment != "dev" && length(var.github_environment_reviewer_logins) > 0 ? [1] : []
    content {
      users = [for u in data.github_user.environment_reviewer : u.id]
    }
  }
}

resource "github_actions_environment_variable" "arm_client_id" {
  repository    = var.github_repo
  environment   = github_repository_environment.terraform.environment
  variable_name = "ARM_CLIENT_ID"
  value         = module.workload_identities.client_ids["gha_terraform"]
}

resource "github_actions_environment_variable" "arm_tenant_id" {
  repository    = var.github_repo
  environment   = github_repository_environment.terraform.environment
  variable_name = "ARM_TENANT_ID"
  value         = data.azurerm_client_config.current.tenant_id
}

resource "github_actions_environment_variable" "arm_subscription_id" {
  repository    = var.github_repo
  environment   = github_repository_environment.terraform.environment
  variable_name = "ARM_SUBSCRIPTION_ID"
  value         = var.subscription_id
}

resource "github_actions_environment_variable" "tf_state_rg" {
  repository    = var.github_repo
  environment   = github_repository_environment.terraform.environment
  variable_name = "TF_STATE_RG"
  value         = var.state_resource_group_name
}

resource "github_actions_environment_variable" "tf_state_account" {
  repository    = var.github_repo
  environment   = github_repository_environment.terraform.environment
  variable_name = "TF_STATE_ACCOUNT"
  value         = var.storage_account_name
}

resource "azuread_directory_role" "cloud_app_admin" {
  count        = var.gha_terraform_application_administrator ? 1 : 0
  display_name = "Cloud Application Administrator"
}

resource "azuread_directory_role_assignment" "gha_terraform_cloud_app_admin" {
  count               = var.gha_terraform_application_administrator ? 1 : 0
  role_id             = azuread_directory_role.cloud_app_admin[0].template_id
  principal_object_id = module.workload_identities.principal_ids["gha_terraform"]
}
