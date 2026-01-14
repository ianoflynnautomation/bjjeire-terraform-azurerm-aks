

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
        id = module.avm-res-network-virtualnetwork.subnets["workload"].resource_id
      }
    }
  }
}
