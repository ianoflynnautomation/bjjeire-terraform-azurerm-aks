
provider "azurerm" {
  subscription_id     = var.subscription_id
  storage_use_azuread = true
  features {
    resource_group {
      prevent_deletion_if_contains_resources = true
    }
  }
}

provider "tls" {}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

# Prefer TF_VAR_github_token (e.g. `gh auth token`) when set. Otherwise the
# GitHub App already required by this stack. The App needs repository
# Secrets + Variables: Read and write to push AZURE_CLIENT_ID after a UAMI
# recreate; until that permission is granted, pass github_token.
provider "github" {
  owner = var.github_org
  token = var.github_token != "" ? var.github_token : null

  dynamic "app_auth" {
    for_each = var.github_token == "" ? [1] : []
    content {
      id              = var.github_app_id
      installation_id = var.github_app_installation_id
      pem_file        = var.github_app_private_key
    }
  }
}
