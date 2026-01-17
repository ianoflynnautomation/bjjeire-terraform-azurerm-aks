data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

resource "tls_private_key" "aks_ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

module "virtual_network" {
  source = "git::https://github.com/Azure/terraform-azurerm-avm-res-network-virtualnetwork.git?ref=c08ca17f59b4f04ee70d9a0928c9bc41738d7ce8" #v0.17.0

  location                = azurerm_resource_group.rg.location
  parent_id               = azurerm_resource_group.rg.id
  address_space           = var.vnet_address_space
  bgp_community           = var.vnet_bgp_community
  ddos_protection_plan    = var.vnet_ddos_protection_plan
  diagnostic_settings     = var.vnet_diagnostic_settings
  dns_servers             = var.vnet_dns_servers
  enable_telemetry        = var.vnet_enable_telemetry
  enable_vm_protection    = var.vnet_enable_vm_protection
  encryption              = var.vnet_encryption
  extended_location       = var.vnet_extended_location
  flow_timeout_in_minutes = var.vnet_flow_timeout_in_minutes
  ipam_pools              = var.vnet_ipam_pools
  lock                    = var.vnet_lock
  name                    = var.vnet_name
  peerings                = var.vnet_peerings
  retry                   = var.vnet_retry
  role_assignments        = var.role_assignments
  subnets = {
    system = {
      name                                          = "SystemSubnet"
      address_prefixes                              = ["10.20.0.0/20"]
      private_endpoint_network_policies             = "Enabled"
      private_link_service_network_policies_enabled = true
      default_outbound_access_enabled               = false
      delegation                                    = null
    }
    workload = {
      name                                          = "RunnerSubnet"
      address_prefixes                              = ["10.20.16.0/20"]
      private_endpoint_network_policies             = "Enabled"
      private_link_service_network_policies_enabled = true
      default_outbound_access_enabled               = false
      delegation                                    = null
    }
  }
  tags     = var.tags
  timeouts = var.timeouts
}

module "key_vault" {
  source = "git::https://github.com/Azure/terraform-azurerm-avm-res-keyvault-vault.git?ref=3735ca49887857467f3030ad72fd43705e1eb387" #v0.10.2

  location                                = azurerm_resource_group.rg.location
  name                                    = var.kv_name
  resource_group_name                     = azurerm_resource_group.rg.name
  tenant_id                               = data.azurerm_client_config.current.tenant_id
  contacts                                = var.kv_contacts
  diagnostic_settings                     = var.kv_diagnostic_settings
  enable_telemetry                        = var.kv_enable_telemetry
  enabled_for_deployment                  = var.kv_enabled_for_deployment
  enabled_for_disk_encryption             = var.kv_enabled_for_disk_encryption
  enabled_for_template_deployment         = var.kv_enabled_for_template_deployment
  keys                                    = var.kv_keys
  legacy_access_policies                  = var.kv_legacy_access_policies
  legacy_access_policies_enabled          = var.kv_legacy_access_policies_enabled
  lock                                    = var.kv_lock
  network_acls                            = var.kv_network_acls
  private_endpoints                       = var.kv_private_endpoints
  private_endpoints_manage_dns_zone_group = var.kv_private_endpoints_manage_dns_zone_group
  public_network_access_enabled           = var.kv_public_network_access_enabled
  purge_protection_enabled                = var.kv_purge_protection_enabled
  role_assignments = {
    terraform_runner = {
      role_definition_id_or_name = "Key Vault Administrator"
      principal_id               = data.azurerm_client_config.current.object_id
    },
    external_secrets_kv_secret_user = {
      role_definition_id_or_name = "Key Vault Secrets User"
      principal_id               = module.external_secrets_identity.principal_id
    },
    flux_kv_secrets_user = {
      role_definition_id_or_name = "Key Vault Secrets User"
      principal_id               = module.flux_identity.principal_id
    },
    observability_kv_secret_user = {
      role_definition_id_or_name = "Key Vault Secrets User"
      principal_id               = module.observability_identity.principal_id
    },
    arc_kv_secret_user = {
      role_definition_id_or_name = "Key Vault Secrets User"
      principal_id               = module.arc_identity.principal_id
    }
  }
  secrets = {
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
  }
  secrets_value = {
    aks_public_ssh_key     = tls_private_key.aks_ssh_key.public_key_openssh
    aks_private_ssh_key    = tls_private_key.aks_ssh_key.private_key_pem
    gh_flux_aks_token      = var.gh_flux_aks_token
    grafana_admin_password = var.grafana_admin_password
  }
  sku_name                                = var.kv_sku_name
  soft_delete_retention_days              = var.kv_soft_delete_retention_days
  tags                                    = var.tags
  wait_for_rbac_before_contact_operations = var.kv_wait_for_rbac_before_contact_operations
  wait_for_rbac_before_key_operations     = var.kv_wait_for_rbac_before_key_operations
  wait_for_rbac_before_secret_operations  = var.kv_wait_for_rbac_before_secret_operations
}

module "aks" {
  source = "git::https://github.com/Azure/terraform-azurerm-aks.git?ref=be56dbf4b3fbde8df7d9df37da2a4ff6a0e98f18" #11.0.0

  location                                                        = azurerm_resource_group.rg.location
  resource_group_name                                             = azurerm_resource_group.rg.name
  aci_connector_linux_enabled                                     = var.aks_aci_connector_linux_enabled
  aci_connector_linux_subnet_name                                 = var.aks_aci_connector_linux_subnet_name
  admin_username                                                  = var.aks_admin_username
  agents_availability_zones                                       = var.aks_agents_availability_zones
  agents_count                                                    = var.aks_agents_count
  agents_labels                                                   = var.aks_agents_labels
  agents_max_count                                                = var.aks_agents_max_count
  agents_min_count                                                = var.aks_agents_min_count
  agents_max_pods                                                 = var.aks_agents_max_pods
  agents_pool_drain_timeout_in_minutes                            = var.aks_agents_pool_drain_timeout_in_minutes
  agents_pool_kubelet_configs                                     = var.aks_agents_pool_kubelet_configs
  agents_pool_linux_os_configs                                    = var.aks_agents_pool_linux_os_configs
  agents_pool_max_surge                                           = var.aks_agents_pool_max_surge
  agents_pool_name                                                = var.aks_agents_pool_name
  agents_pool_node_soak_duration_in_minutes                       = var.aks_agents_pool_node_soak_duration_in_minutes
  agents_proximity_placement_group_id                             = var.aks_agents_proximity_placement_group_id
  agents_size                                                     = var.aks_agents_size
  agents_tags                                                     = var.aks_agents_tags
  agents_type                                                     = var.aks_agents_type
  api_server_authorized_ip_ranges                                 = var.aks_api_server_authorized_ip_ranges
  attached_acr_id_map                                             = var.aks_attached_acr_id_map
  auto_scaler_profile_balance_similar_node_groups                 = var.aks_auto_scaler_profile_balance_similar_node_groups
  auto_scaler_profile_empty_bulk_delete_max                       = var.aks_auto_scaler_profile_empty_bulk_delete_max
  auto_scaler_profile_enabled                                     = var.aks_auto_scaler_profile_enabled
  auto_scaler_profile_expander                                    = var.aks_auto_scaler_profile_expander
  auto_scaler_profile_max_graceful_termination_sec                = var.aks_auto_scaler_profile_max_graceful_termination_sec
  auto_scaler_profile_max_node_provisioning_time                  = var.aks_auto_scaler_profile_max_node_provisioning_time
  auto_scaler_profile_max_unready_nodes                           = var.aks_auto_scaler_profile_max_unready_nodes
  auto_scaler_profile_max_unready_percentage                      = var.aks_auto_scaler_profile_max_unready_percentage
  auto_scaler_profile_new_pod_scale_up_delay                      = var.aks_auto_scaler_profile_new_pod_scale_up_delay
  auto_scaler_profile_scale_down_delay_after_add                  = var.aks_auto_scaler_profile_scale_down_delay_after_add
  auto_scaler_profile_scale_down_delay_after_delete               = var.aks_auto_scaler_profile_scale_down_delay_after_delete
  auto_scaler_profile_scale_down_delay_after_failure              = var.aks_auto_scaler_profile_scale_down_delay_after_failure
  auto_scaler_profile_scale_down_unneeded                         = var.aks_auto_scaler_profile_scale_down_unneeded
  auto_scaler_profile_scale_down_unready                          = var.aks_auto_scaler_profile_scale_down_unready
  auto_scaler_profile_scale_down_utilization_threshold            = var.aks_auto_scaler_profile_scale_down_utilization_threshold
  auto_scaler_profile_scan_interval                               = var.aks_auto_scaler_profile_scan_interval
  auto_scaler_profile_skip_nodes_with_local_storage               = var.aks_auto_scaler_profile_skip_nodes_with_local_storage
  auto_scaler_profile_skip_nodes_with_system_pods                 = var.aks_auto_scaler_profile_skip_nodes_with_system_pods
  auto_scaling_enabled                                            = var.aks_auto_scaling_enabled
  automatic_channel_upgrade                                       = var.aks_automatic_channel_upgrade
  azure_policy_enabled                                            = var.aks_azure_policy_enabled
  brown_field_application_gateway_for_ingress                     = var.aks_brown_field_application_gateway_for_ingress
  client_id                                                       = var.aks_client_id
  client_secret                                                   = var.aks_client_secret
  cluster_log_analytics_workspace_name                            = var.aks_cluster_log_analytics_workspace_name
  cluster_name                                                    = var.aks_cluster_name
  cluster_name_random_suffix                                      = var.aks_cluster_name_random_suffix
  confidential_computing                                          = var.aks_confidential_computing
  cost_analysis_enabled                                           = var.aks_cost_analysis_enabled
  create_monitor_data_collection_rule                             = var.aks_create_monitor_data_collection_rule
  create_role_assignment_network_contributor                      = var.aks_create_role_assignment_network_contributor
  create_role_assignments_for_application_gateway                 = var.aks_create_role_assignments_for_application_gateway
  default_node_pool_fips_enabled                                  = var.aks_default_node_pool_fips_enabled
  disk_encryption_set_id                                          = var.aks_disk_encryption_set_id
  dns_prefix_private_cluster                                      = var.aks_dns_prefix_private_cluster
  ebpf_data_plane                                                 = var.aks_ebpf_data_plane
  green_field_application_gateway_for_ingress                     = var.aks_green_field_application_gateway_for_ingress
  host_encryption_enabled                                         = var.aks_host_encryption_enabled
  http_proxy_config                                               = var.aks_http_proxy_config
  identity_ids                                                    = [module.cluster_identity.id]
  identity_type                                                   = var.aks_identity_type
  image_cleaner_enabled                                           = var.aks_image_cleaner_enabled
  interval_before_cluster_update                                  = var.aks_interval_before_cluster_update
  key_vault_secrets_provider_enabled                              = var.aks_key_vault_secrets_provider_enabled
  kms_enabled                                                     = var.aks_kms_enabled
  kms_key_vault_key_id                                            = var.aks_kms_key_vault_key_id
  kms_key_vault_network_access                                    = var.aks_kms_key_vault_network_access
  kubelet_identity                                                = var.aks_kubelet_identity
  kubernetes_version                                              = var.aks_kubernetes_version
  load_balancer_profile_enabled                                   = var.aks_load_balancer_profile_enabled
  load_balancer_profile_idle_timeout_in_minutes                   = var.aks_load_balancer_profile_idle_timeout_in_minutes
  load_balancer_profile_managed_outbound_ip_count                 = var.aks_load_balancer_profile_managed_outbound_ip_count
  load_balancer_profile_managed_outbound_ipv6_count               = var.aks_load_balancer_profile_managed_outbound_ipv6_count
  load_balancer_profile_outbound_ip_address_ids                   = var.aks_load_balancer_profile_outbound_ip_address_ids
  load_balancer_profile_outbound_ip_prefix_ids                    = var.aks_load_balancer_profile_outbound_ip_prefix_ids
  load_balancer_profile_outbound_ports_allocated                  = var.aks_load_balancer_profile_outbound_ports_allocated
  load_balancer_sku                                               = var.aks_load_balancer_sku
  local_account_disabled                                          = var.aks_local_account_disabled
  log_analytics_solution                                          = var.aks_log_analytics_solution
  log_analytics_workspace_enabled                                 = var.aks_log_analytics_workspace_enabled
  log_analytics_workspace                                         = var.aks_log_analytics_workspace
  log_analytics_workspace_allow_resource_only_permissions         = var.aks_log_analytics_workspace_allow_resource_only_permissions
  log_analytics_workspace_cmk_for_query_forced                    = var.aks_log_analytics_workspace_cmk_for_query_forced
  log_analytics_workspace_daily_quota_gb                          = var.aks_log_analytics_workspace_daily_quota_gb
  log_analytics_workspace_data_collection_rule_id                 = var.aks_log_analytics_workspace_data_collection_rule_id
  log_analytics_workspace_identity                                = var.aks_log_analytics_workspace_identity
  log_analytics_workspace_immediate_data_purge_on_30_days_enabled = var.aks_log_analytics_workspace_immediate_data_purge_on_30_days_enabled
  log_analytics_workspace_internet_ingestion_enabled              = var.aks_log_analytics_workspace_internet_ingestion_enabled
  log_analytics_workspace_internet_query_enabled                  = var.aks_log_analytics_workspace_internet_query_enabled
  log_analytics_workspace_local_authentication_disabled           = var.aks_log_analytics_workspace_local_authentication_disabled
  log_analytics_workspace_reservation_capacity_in_gb_per_day      = var.aks_log_analytics_workspace_reservation_capacity_in_gb_per_day
  log_analytics_workspace_resource_group_name                     = var.aks_log_analytics_workspace_resource_group_name
  log_analytics_workspace_sku                                     = var.aks_log_analytics_workspace_sku
  log_retention_in_days                                           = var.aks_log_retention_in_days
  maintenance_window                                              = var.aks_maintenance_window
  maintenance_window_auto_upgrade                                 = var.aks_maintenance_window_auto_upgrade
  microsoft_defender_enabled                                      = var.aks_microsoft_defender_enabled
  monitor_data_collection_rule_data_sources_syslog_facilities     = var.aks_monitor_data_collection_rule_data_sources_syslog_facilities
  monitor_data_collection_rule_data_sources_syslog_levels         = var.aks_monitor_data_collection_rule_data_sources_syslog_levels
  monitor_data_collection_rule_extensions_streams                 = var.aks_monitor_data_collection_rule_extensions_streams
  monitor_metrics                                                 = var.aks_monitor_metrics
  msi_auth_for_monitoring_enabled                                 = var.aks_msi_auth_for_monitoring_enabled
  nat_gateway_profile                                             = var.aks_nat_gateway_profile
  net_profile_dns_service_ip                                      = var.aks_net_profile_dns_service_ip
  net_profile_outbound_type                                       = var.aks_net_profile_outbound_type
  net_profile_pod_cidr                                            = var.aks_net_profile_pod_cidr
  net_profile_service_cidr                                        = var.aks_net_profile_service_cidr
  network_contributor_role_assigned_subnet_ids                    = var.aks_network_contributor_role_assigned_subnet_ids
  network_plugin                                                  = var.aks_network_plugin
  network_plugin_mode                                             = var.aks_network_plugin_mode
  network_policy                                                  = var.aks_network_policy
  node_network_profile                                            = var.aks_node_network_profile
  node_os_channel_upgrade                                         = var.aks_node_os_channel_upgrade
  node_pools                                                      = local.workload_node_pools
  node_public_ip_enabled                                          = var.aks_node_public_ip_enabled
  node_resource_group                                             = var.aks_node_resource_group
  oidc_issuer_enabled                                             = var.aks_oidc_issuer_enabled
  oms_agent_enabled                                               = var.aks_oms_agent_enabled
  only_critical_addons_enabled                                    = var.aks_only_critical_addons_enabled
  open_service_mesh_enabled                                       = var.aks_open_service_mesh_enabled
  orchestrator_version                                            = var.aks_orchestrator_version
  os_disk_size_gb                                                 = var.aks_os_disk_size_gb
  os_disk_type                                                    = var.aks_os_disk_type
  os_sku                                                          = var.aks_os_sku
  pod_subnet                                                      = var.aks_pod_subnet
  prefix                                                          = var.aks_prefix
  private_cluster_enabled                                         = var.aks_private_cluster_enabled
  private_cluster_public_fqdn_enabled                             = var.aks_private_cluster_public_fqdn_enabled
  private_dns_zone_id                                             = var.aks_private_dns_zone_id
  public_ssh_key                                                  = tls_private_key.aks_ssh_key.public_key_openssh
  rbac_aad_admin_group_object_ids                                 = var.aks_rbac_aad_admin_group_object_ids
  rbac_aad_azure_rbac_enabled                                     = var.aks_rbac_aad_azure_rbac_enabled
  rbac_aad_tenant_id                                              = data.azurerm_client_config.current.tenant_id
  role_based_access_control_enabled                               = var.aks_role_based_access_control_enabled
  run_command_enabled                                             = var.ask_run_command_enabled
  scale_down_mode                                                 = var.aks_scale_down_mode
  secret_rotation_enabled                                         = var.aks_secret_rotation_enabled
  secret_rotation_interval                                        = var.aks_secret_rotation_interval
  service_mesh_profile                                            = var.aks_service_mesh_profile
  sku_tier                                                        = var.aks_sku_tier
  snapshot_id                                                     = var.aks_snapshot_id
  storage_profile_blob_driver_enabled                             = var.aks_storage_profile_blob_driver_enabled
  storage_profile_disk_driver_enabled                             = var.aks_storage_profile_disk_driver_enabled
  storage_profile_enabled                                         = var.aks_storage_profile_enabled
  storage_profile_file_driver_enabled                             = var.aks_storage_profile_file_driver_enabled
  storage_profile_snapshot_controller_enabled                     = var.aks_storage_profile_snapshot_controller_enabled
  support_plan                                                    = var.aks_support_plan
  tags                                                            = var.tags
  temporary_name_for_rotation                                     = var.aks_temporary_name_for_rotation
  upgrade_override                                                = var.aks_upgrade_override
  vnet_subnet = {
    id = module.virtual_network.subnets["workload"].resource_id
  }
  web_app_routing             = var.aks_web_app_routing
  workload_autoscaler_profile = var.aks_workload_autoscaler_profile
  workload_identity_enabled   = var.aks_workload_identity_enabled

  depends_on = [
    module.virtual_network
  ]
}
