locals {
  nat_gateway_name           = coalesce(var.nat_gateway_name, "natgw-${var.aks_cluster_name}")
  nat_gateway_public_ip_name = coalesce(var.nat_gateway_public_ip_name, "pip-natgw-${var.aks_cluster_name}")
  nat_gateway_public_ip_sku  = var.nat_gateway_sku_name == "StandardV2" ? "StandardV2" : "Standard"

  # NAT is created first and associated here so node subnets have egress
  # while default_outbound_access_enabled stays false (no implicit Azure
  # SNAT). The private-endpoint subnet is inbound-only and is not NATed.
  subnets = {
    system = {
      name                                          = var.system_subnet_name
      address_prefixes                              = var.system_subnet_address_prefixes
      private_endpoint_network_policies             = "Enabled"
      private_link_service_network_policies_enabled = true
      default_outbound_access_enabled               = false
      nat_gateway = {
        id = module.nat_gateway.resource_id
      }
    }
    workload = {
      name                                          = var.workload_subnet_name
      address_prefixes                              = var.workload_subnet_address_prefixes
      private_endpoint_network_policies             = "Enabled"
      private_link_service_network_policies_enabled = true
      default_outbound_access_enabled               = false
      nat_gateway = {
        id = module.nat_gateway.resource_id
      }
      network_security_group = var.enable_cloudflare_origin_lockdown ? {
        id = module.cloudflare_ingress_nsg[0].resource_id
      } : null
    }
    private_endpoints = {
      name                                          = var.private_endpoint_subnet_name
      address_prefixes                              = var.private_endpoint_subnet_address_prefixes
      private_endpoint_network_policies             = "Disabled"
      private_link_service_network_policies_enabled = true
      default_outbound_access_enabled               = false
    }
  }
}

module "nat_gateway" {
  source  = "Azure/avm-res-network-natgateway/azurerm"
  version = "0.3.2"

  location  = module.rg.location
  parent_id = module.rg.resource_id
  name      = local.nat_gateway_name

  sku_name                = var.nat_gateway_sku_name
  idle_timeout_in_minutes = var.nat_gateway_idle_timeout_in_minutes
  enable_telemetry        = var.vnet_enable_telemetry
  tags                    = var.tags

  public_ips = {
    ip_1 = {
      name = local.nat_gateway_public_ip_name
    }
  }

  public_ip_configuration = {
    ip_1 = {
      sku   = local.nat_gateway_public_ip_sku
      zones = var.nat_gateway_sku_name == "StandardV2" ? ["1", "2", "3"] : null
    }
  }
}

module "virtual_network" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "0.22.2"

  location                = module.rg.location
  parent_id               = module.rg.resource_id
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

module "kv_private_dns_zone" {
  source  = "Azure/avm-res-network-privatednszone/azurerm"
  version = "0.5.0"

  parent_id        = module.rg.resource_id
  domain_name      = "privatelink.vaultcore.azure.net"
  enable_telemetry = var.vnet_enable_telemetry
  tags             = var.tags

  virtual_network_links = {
    aks = {
      name                                   = "kv-${var.aks_cluster_name}"
      virtual_network_id                     = module.virtual_network.resource_id
      registration_enabled                   = false
      private_dns_zone_supports_private_link = true
    }
  }
}
