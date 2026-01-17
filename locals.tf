

locals {

  resource_type_uai = "uami"
  region            = "swn"

  uami_name = {
    extern_secrets = "${local.resource_type_uai}-extsecrets-${var.environment}-${local.region}"
    observability  = "${local.resource_type_uai}-obs-${var.environment}-${local.region}"
    arc            = "${local.resource_type_uai}-arc-${var.environment}-${local.region}"
    flux           = "${local.resource_type_uai}-flux-${var.environment}-${local.region}"
    control_plane  = "${local.resource_type_uai}-cp-${var.environment}-${local.region}"
    github         = "id-bjjeire-github-actions-${var.environment}-${local.region}"
  }

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
