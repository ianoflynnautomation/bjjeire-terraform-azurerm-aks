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
      network_security_group = var.enable_cloudflare_origin_lockdown ? {
        id = module.cloudflare_ingress_nsg[0].resource_id
      } : null
    }
  }
}

module "virtual_network" {
  source = "git::https://github.com/Azure/terraform-azurerm-avm-res-network-virtualnetwork.git?ref=7700fb912c3e735b2806faee01e7682af425c46d" #v0.19.0

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
  subnets                 = local.subnets
  tags                    = var.tags
  timeouts                = var.timeouts
}
