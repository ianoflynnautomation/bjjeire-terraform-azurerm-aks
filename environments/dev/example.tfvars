
subscription_id                                          = ""
gh_flux_aks_token                                        = ""
resource_group_name                                      = ""
location                                                 = ""
grafana_admin_password                                   = ""
aks_cluster_name                                         = ""
aks_sku_tier                                             = ""
aks_agents_count                                         = null
aks_agents_size                                          = ""
aks_kubernetes_version                                   = ""
aks_os_disk_size_gb                                      = 128
aks_os_disk_type                                         = ""
aks_prefix                                               = ""
aks_network_plugin                                       = ""
aks_network_policy                                       = ""
aks_create_role_assignments_for_application_gateway      = false
aks_rbac_aad_admin_group_object_ids                      = [""]
aks_auto_scaling_enabled                                 = true
aks_agents_min_count                                     = 1
aks_agents_max_count                                     = 3
aks_oidc_issuer_enabled                                  = true
aks_workload_identity_enabled                            = true
aks_role_based_access_control_enabled                    = true
aks_rbac_aad_azure_rbac_enabled                          = true
aks_log_analytics_workspace_enabled                      = false
aks_microsoft_defender_enabled                           = false
aks_azure_policy_enabled                                 = false
aks_private_cluster_enabled                              = false
aks_node_public_ip_enabled                               = true
aks_local_account_disabled                               = false
aks_auto_scaler_profile_enabled                          = true
aks_auto_scaler_profile_scale_down_delay_after_add       = "5m"
aks_auto_scaler_profile_scale_down_unneeded              = "5m"
aks_auto_scaler_profile_scale_down_utilization_threshold = "0.5"
aks_auto_scaler_profile_max_graceful_termination_sec     = "300"
aks_auto_scaler_profile_skip_nodes_with_local_storage    = false
aks_identity_type                                        = "UserAssigned"
aks_kms_enabled                                          = false
aks_temporary_name_for_rotation                          = ""
kv_name                                                  = ""
kv_sku_name                                              = ""
kv_purge_protection_enabled                              = false
kv_soft_delete_retention_days                            = 7
vnet_name                                                = ""
vnet_address_space                                       = [""]
tags = {
  environment = "test"
  cost-center = "development"
  auto-stop   = "enabled"
}
kv_network_acls = {
  bypass                     = ""
  default_action             = ""
  ip_rules                   = []
  virtual_network_subnet_ids = []
}

kv_keys = {
  "sops-encryption-key" = {
    name     = "sops-encryption-key"
    key_type = "RSA"
    key_opts = ["encrypt", "decrypt"]
    key_size = 2048
  }
}
