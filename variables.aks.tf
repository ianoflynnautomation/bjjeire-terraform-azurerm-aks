variable "aks_ssh_key_algorithm" {
  type        = string
  default     = "RSA"
  description = "Algorithm for the tls_private_key generated for AKS node SSH access."
}

variable "aks_ssh_key_rsa_bits" {
  type        = number
  default     = 4096
  description = "RSA key length in bits for the AKS node SSH private key."
}

variable "aks_admin_username" {
  type        = string
  default     = "azureuser"
  description = "Linux admin username for node SSH login."
  nullable    = false
}

variable "aks_cluster_name" {
  type        = string
  description = "Name for the AKS cluster. Required — embedded in NSG name (main.nsg.tf) and oauth2-proxy app registration display name (main.oauth2.tf), so null causes string-interpolation failures at plan/lint time."
  nullable    = false

  validation {
    condition     = length(trimspace(var.aks_cluster_name)) > 0
    error_message = "aks_cluster_name must be a non-empty string."
  }
}

variable "aks_kubernetes_version" {
  type        = string
  default     = null
  description = "Kubernetes version. When null, the AVM module uses the AKS default."
}

variable "aks_sku_name" {
  type        = string
  default     = "Base"
  description = "Managed cluster SKU name (Base or Automatic)."
  nullable    = false

  validation {
    condition     = contains(["Base", "Automatic"], var.aks_sku_name)
    error_message = "aks_sku_name must be Base or Automatic."
  }
}

variable "aks_sku_tier" {
  type        = string
  default     = "Free"
  description = "Managed cluster SKU tier (Free, Standard, Premium)."
  nullable    = false

  validation {
    condition     = contains(["Free", "Standard", "Premium"], var.aks_sku_tier)
    error_message = "aks_sku_tier must be Free, Standard, or Premium."
  }
}

variable "aks_prefix" {
  type        = string
  default     = null
  description = "DNS prefix for the AKS cluster."
}

variable "aks_node_resource_group" {
  type        = string
  default     = null
  description = "Name of the resource group AKS uses for cluster-managed resources (node pools, VMSS, NICs)."
}

variable "aks_enable_telemetry" {
  type        = bool
  default     = false
  description = "Enable AVM module telemetry (modtm provider)."
  nullable    = false
}

variable "aks_agents_pool_name" {
  type        = string
  default     = "system"
  description = "Name of the default (system) node pool."
  nullable    = false
}

variable "aks_agents_size" {
  type        = string
  default     = "Standard_D2s_v3"
  description = "VM size for the default node pool."
  nullable    = false
}

variable "aks_agents_count" {
  type        = number
  default     = null
  description = "Static node count for the default node pool. Set to null when aks_auto_scaling_enabled = true."
}

variable "aks_agents_min_count" {
  type        = number
  default     = null
  description = "Minimum node count for the default node pool when autoscaling is enabled."
}

variable "aks_agents_max_count" {
  type        = number
  default     = null
  description = "Maximum node count for the default node pool when autoscaling is enabled."
}

variable "aks_agents_max_pods" {
  type        = number
  default     = null
  description = "Maximum number of pods per node."
}

variable "aks_auto_scaling_enabled" {
  type        = bool
  default     = true
  description = "Whether the default node pool autoscales between min_count and max_count."
  nullable    = false
}

variable "aks_os_disk_size_gb" {
  type        = number
  default     = null
  description = "Size of the OS disk attached to each node in GiB."
}

variable "aks_os_disk_type" {
  type        = string
  default     = null
  description = "OS disk type (Managed or Ephemeral)."

  validation {
    condition     = var.aks_os_disk_type == null || contains(["Managed", "Ephemeral"], coalesce(var.aks_os_disk_type, "Managed"))
    error_message = "aks_os_disk_type must be Managed or Ephemeral."
  }
}

variable "aks_node_public_ip_enabled" {
  type        = bool
  default     = false
  description = "Assign a public IP per node. Keep false unless explicitly required."
  nullable    = false
}

variable "aks_temporary_name_for_rotation" {
  type        = string
  default     = "aksrotate"
  description = "Temporary node pool name used during VM-size rotations of the default pool."
  nullable    = false
}

variable "aks_agents_availability_zones" {
  type        = list(string)
  default     = null
  description = "Availability zones the default node pool is spread across."
}

variable "aks_network_plugin" {
  type        = string
  default     = "azure"
  description = "Network plugin used by the cluster (azure, kubenet, none)."
  nullable    = false
}

variable "aks_network_policy" {
  type        = string
  default     = null
  description = "Network policy mode (azure, calico, cilium)."
}

variable "aks_load_balancer_sku" {
  type        = string
  default     = "standard"
  description = "Load balancer SKU (standard or basic)."
  nullable    = false
}

variable "aks_role_based_access_control_enabled" {
  type        = bool
  default     = true
  description = "Enable Kubernetes RBAC."
  nullable    = false
}

variable "aks_local_account_disabled" {
  type        = bool
  default     = true
  description = "Disable local admin accounts (use Azure AD auth only)."
  nullable    = false
}

variable "aks_rbac_aad_azure_rbac_enabled" {
  type        = bool
  default     = true
  description = "Enable Azure RBAC for Kubernetes authorization."
  nullable    = false
}

variable "aks_rbac_aad_admin_group_object_ids" {
  type        = list(string)
  default     = []
  description = "Fallback Entra group object IDs granted cluster-admin. Used only when var.aks_admin_group_display_names yields no matches via the group data source in main.groups.tf."
  nullable    = false
}

variable "aks_oidc_issuer_enabled" {
  type        = bool
  default     = true
  description = "Enable the OIDC issuer (required for workload identity)."
  nullable    = false
}

variable "aks_workload_identity_enabled" {
  type        = bool
  default     = true
  description = "Enable workload identity on the cluster."
  nullable    = false
}

variable "aks_private_cluster_enabled" {
  type        = bool
  default     = false
  description = "Make the API server reachable only via a private endpoint."
  nullable    = false
}

variable "aks_api_server_authorized_ip_ranges" {
  type        = list(string)
  default     = null
  description = "CIDR ranges allowed to reach the public API server. Ignored when aks_private_cluster_enabled = true."
}

variable "aks_microsoft_defender_enabled" {
  type        = bool
  default     = false
  description = "Enable Microsoft Defender security monitoring."
  nullable    = false
}

variable "aks_auto_scaler_profile_enabled" {
  type        = bool
  default     = true
  description = "When true the auto_scaler_profile object is sent to the API; when false the AVM module receives null."
  nullable    = false
}

variable "aks_auto_scaler_profile_scale_down_delay_after_add" {
  type        = string
  default     = "10m"
  description = "How long the autoscaler waits after a scale-up before considering scale-downs."
  nullable    = false
}

variable "aks_auto_scaler_profile_scale_down_unneeded" {
  type        = string
  default     = "10m"
  description = "How long a node must be unneeded before the autoscaler removes it."
  nullable    = false
}

variable "aks_auto_scaler_profile_scale_down_utilization_threshold" {
  type        = string
  default     = "0.5"
  description = "Utilization threshold below which the autoscaler considers a node for removal."
  nullable    = false
}

variable "aks_auto_scaler_profile_max_graceful_termination_sec" {
  type        = string
  default     = "600"
  description = "Maximum graceful termination time (seconds) for pods during scale-down."
  nullable    = false
}

variable "aks_auto_scaler_profile_skip_nodes_with_local_storage" {
  type        = bool
  default     = true
  description = "Skip removing nodes with local storage during scale-down."
  nullable    = false
}
