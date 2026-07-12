resource "tls_private_key" "aks_ssh_key" {
  algorithm = var.aks_ssh_key_algorithm
  rsa_bits  = var.aks_ssh_key_rsa_bits
}

locals {
  workload_node_pools = {
    runners = {
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
      vnet_subnet_id  = module.virtual_network.subnets["workload"].resource_id
    }
  }
}

module "aks" {
  source = "git::https://github.com/Azure/terraform-azurerm-avm-res-containerservice-managedcluster.git?ref=2d0302e9d8c450df2d1b257c32823b00b3557c96" # v0.6.7

  location  = azurerm_resource_group.rg.location
  parent_id = azurerm_resource_group.rg.id
  name      = var.aks_cluster_name

  enable_telemetry = var.aks_enable_telemetry
  tags             = var.tags

  kubernetes_version  = var.aks_kubernetes_version
  dns_prefix          = var.aks_prefix
  node_resource_group = var.aks_node_resource_group

  sku = {
    name = var.aks_sku_name
    tier = var.aks_sku_tier
  }

  managed_identities = {
    system_assigned            = false
    user_assigned_resource_ids = [module.cluster_identity.resource_id]
  }

  enable_rbac            = var.aks_role_based_access_control_enabled
  disable_local_accounts = var.aks_local_account_disabled

  aad_profile = {
    managed                = true
    tenant_id              = data.azurerm_client_config.current.tenant_id
    enable_azure_rbac      = var.aks_rbac_aad_azure_rbac_enabled
    admin_group_object_ids = length(local.aks_admin_group_object_ids) > 0 ? local.aks_admin_group_object_ids : var.aks_rbac_aad_admin_group_object_ids
  }

  oidc_issuer_profile = {
    enabled = var.aks_oidc_issuer_enabled
  }

  api_server_access_profile = {
    enable_private_cluster = var.aks_private_cluster_enabled
    authorized_ip_ranges   = var.aks_api_server_authorized_ip_ranges
  }

  default_agent_pool = {
    name                        = var.aks_agents_pool_name
    vm_size                     = var.aks_agents_size
    count_of                    = var.aks_agents_count
    enable_auto_scaling         = var.aks_auto_scaling_enabled
    min_count                   = var.aks_agents_min_count
    max_count                   = var.aks_agents_max_count
    max_pods                    = var.aks_agents_max_pods
    os_disk_size_gb             = var.aks_os_disk_size_gb
    os_disk_type                = var.aks_os_disk_type
    enable_node_public_ip       = var.aks_node_public_ip_enabled
    temporary_name_for_rotation = var.aks_temporary_name_for_rotation
    availability_zones          = var.aks_agents_availability_zones
    vnet_subnet_id              = module.virtual_network.subnets["workload"].resource_id
  }

  network_profile = {
    network_plugin    = var.aks_network_plugin
    network_policy    = var.aks_network_policy
    load_balancer_sku = var.aks_load_balancer_sku
  }

  auto_scaler_profile = var.aks_auto_scaler_profile_enabled ? {
    scale_down_delay_after_add       = var.aks_auto_scaler_profile_scale_down_delay_after_add
    scale_down_unneeded              = var.aks_auto_scaler_profile_scale_down_unneeded
    scale_down_utilization_threshold = var.aks_auto_scaler_profile_scale_down_utilization_threshold
    max_graceful_termination_sec     = var.aks_auto_scaler_profile_max_graceful_termination_sec
    skip_nodes_with_local_storage    = var.aks_auto_scaler_profile_skip_nodes_with_local_storage
  } : null

  security_profile = {
    workload_identity = {
      enabled = var.aks_workload_identity_enabled
    }
    defender = var.aks_microsoft_defender_enabled ? {
      security_monitoring = {
        enabled = true
      }
    } : null
  }

  linux_profile = {
    admin_username = var.aks_admin_username
    ssh = {
      public_keys = [{
        key_data = tls_private_key.aks_ssh_key.public_key_openssh
      }]
    }
  }

  depends_on = [module.virtual_network]
}

module "workload_node_pools" {
  source   = "git::https://github.com/Azure/terraform-azurerm-avm-res-containerservice-managedcluster.git//modules/agentpool?ref=2d0302e9d8c450df2d1b257c32823b00b3557c96" # v0.6.7
  for_each = local.workload_node_pools

  parent_id = module.aks.resource_id

  name                      = each.value.name
  mode                      = each.value.mode
  vm_size                   = each.value.vm_size
  scale_set_priority        = each.value.priority
  scale_set_eviction_policy = each.value.eviction_policy
  spot_max_price            = each.value.spot_max_price
  enable_auto_scaling       = each.value.auto_scaling_enabled
  min_count                 = each.value.min_count
  max_count                 = each.value.max_count
  os_disk_type              = each.value.os_disk_type
  os_disk_size_gb           = each.value.os_disk_size_gb
  max_pods                  = each.value.max_pods
  node_labels               = each.value.node_labels
  node_taints               = each.value.node_taints
  scale_down_mode           = each.value.scale_down_mode
  vnet_subnet_id            = each.value.vnet_subnet_id
  tags                      = var.tags
}
