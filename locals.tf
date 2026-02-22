#--------------------------------------------------------------
# Subnet Definitions
#--------------------------------------------------------------

locals {
  subnets = {
    system = {
      name                                          = var.system_subnet_name
      address_prefixes                              = var.system_subnet_address_prefixes
      private_endpoint_network_policies             = "Enabled"
      private_link_service_network_policies_enabled = true
      default_outbound_access_enabled               = false
      delegation                                    = null
    }
    workload = {
      name                                          = var.workload_subnet_name
      address_prefixes                              = var.workload_subnet_address_prefixes
      private_endpoint_network_policies             = "Enabled"
      private_link_service_network_policies_enabled = true
      default_outbound_access_enabled               = false
      delegation                                    = null
    }
  }
}

#--------------------------------------------------------------
# Key Vault Secrets
#--------------------------------------------------------------

locals {
  kv_secret_definitions = {
    aks_public_ssh_key = {
      name         = "aks-ssh-public-key"
      content_type = "text/plain"
    }
    aks_private_ssh_key = {
      name         = "aks-ssh-private-key"
      content_type = "text/plain"
    }
    gh_flux_aks_token = {
      name         = "gh-flux-aks-token"
      content_type = "text/plain"
    }
    grafana_admin_password = {
      name         = "grafana-admin-password"
      content_type = "text/plain"
    }
    cloudflare_api_token = {
      name         = "cloudflare-api-token"
      content_type = "text/plain"
    }
    private_email = {
      name         = "private-email-address"
      content_type = "text/plain"
    }
    oauth2_proxy_cookie_secret = {
      name         = "oauth2-proxy-cookie-secret"
      content_type = "text/plain"
    }
    oauth2_proxy_client_secret = {
      name         = "oauth2-proxy-client-secret"
      content_type = "text/plain"
    }
  }

  kv_secret_values = {
    aks_public_ssh_key         = tls_private_key.aks_ssh_key.public_key_openssh
    aks_private_ssh_key        = tls_private_key.aks_ssh_key.private_key_pem
    gh_flux_aks_token          = var.gh_flux_aks_token
    grafana_admin_password     = var.grafana_admin_password
    cloudflare_api_token       = var.cloudflare_api_token
    private_email              = var.private_email
    oauth2_proxy_cookie_secret = base64encode(random_password.oauth2_cookie_secret.result)
    oauth2_proxy_client_secret = azuread_application_password.oauth2_proxy.value
  }

  kv_role_assignments = {
    terraform_runner = {
      role_definition_id_or_name = "Key Vault Administrator"
      principal_id               = data.azurerm_client_config.current.object_id
    }
    external_secrets_kv_secret_user = {
      role_definition_id_or_name = "Key Vault Secrets User"
      principal_id               = module.external_secrets_identity.principal_id
    }
    flux_kv_secrets_user = {
      role_definition_id_or_name = "Key Vault Secrets User"
      principal_id               = module.flux_identity.principal_id
    }
  }
}

#--------------------------------------------------------------
# Workload Node Pools
#--------------------------------------------------------------

locals {
  workload_node_pools = {
    workload_node_pools = {
      name                 = "runners"
      mode                 = "User"
      vm_size              = "Standard_D4ds_v5"
      priority             = "Spot"
      eviction_policy      = "Delete"
      spot_max_price       = -1
      auto_scaling_enabled = true
      min_count            = 0
      max_count            = 5
      os_disk_type         = "Ephemeral"
      os_disk_size_gb      = 128
      max_pods             = 110
      node_labels = {
        "workload"                              = "gha-runner"
        "kubernetes.azure.com/scalesetpriority" = "spot"
      }
      node_taints = [
        "dedicated=gha-runner:NoSchedule",
        "kubernetes.azure.com/scalesetpriority=spot:NoSchedule"
      ]
      scale_down_mode = "Delete"
      vnet_subnet = {
        id = module.virtual_network.subnets["workload"].resource_id
      }
    }
  }
}
