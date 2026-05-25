
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
