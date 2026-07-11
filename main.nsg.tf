locals {
  # Source of truth: https://www.cloudflare.com/ips-v4 — refresh periodically.
  # Override per-env via var.cloudflare_ipv4_ranges if you need to pin a snapshot.
  cloudflare_ipv4_default = [
    "173.245.48.0/20",
    "103.21.244.0/22",
    "103.22.200.0/22",
    "103.31.4.0/22",
    "141.101.64.0/18",
    "108.162.192.0/18",
    "190.93.240.0/20",
    "188.114.96.0/20",
    "197.234.240.0/22",
    "198.41.128.0/17",
    "162.158.0.0/15",
    "104.16.0.0/13",
    "104.24.0.0/14",
    "172.64.0.0/13",
    "131.0.72.0/22",
  ]

  cloudflare_ipv4_effective = length(var.cloudflare_ipv4_ranges) > 0 ? var.cloudflare_ipv4_ranges : local.cloudflare_ipv4_default

  nsg_access_allow      = "Allow"
  nsg_access_deny       = "Deny"
  nsg_direction_inbound = "Inbound"
  nsg_any_port_range    = "*"
  nsg_any_address       = "*"
  nsg_internet_prefix   = "Internet"
}

module "cloudflare_ingress_nsg" {
  source = "git::https://github.com/Azure/terraform-azurerm-avm-res-network-networksecuritygroup.git?ref=ae82f649ff4e2f0a9d31a18b9c9cd227b1b9b497" #v0.5.1
  count  = var.enable_cloudflare_origin_lockdown ? 1 : 0

  name                = "${var.aks_cluster_name}${var.cloudflare_nsg_name_suffix}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags

  security_rules = {
    allow_cloudflare_https = {
      name                       = "AllowCloudflareHTTPSInbound"
      access                     = local.nsg_access_allow
      direction                  = local.nsg_direction_inbound
      protocol                   = var.cloudflare_nsg_protocol
      priority                   = var.cloudflare_nsg_allow_https_priority
      source_port_range          = local.nsg_any_port_range
      destination_port_range     = var.cloudflare_nsg_https_port
      source_address_prefixes    = toset(local.cloudflare_ipv4_effective)
      destination_address_prefix = local.nsg_any_address
    }
    allow_cloudflare_http = {
      name                       = "AllowCloudflareHTTPInbound"
      access                     = local.nsg_access_allow
      direction                  = local.nsg_direction_inbound
      protocol                   = var.cloudflare_nsg_protocol
      priority                   = var.cloudflare_nsg_allow_http_priority
      source_port_range          = local.nsg_any_port_range
      destination_port_range     = var.cloudflare_nsg_http_port
      source_address_prefixes    = toset(local.cloudflare_ipv4_effective)
      destination_address_prefix = local.nsg_any_address
    }
    deny_internet_https = {
      name                       = "DenyInternetHTTPSInbound"
      access                     = local.nsg_access_deny
      direction                  = local.nsg_direction_inbound
      protocol                   = var.cloudflare_nsg_protocol
      priority                   = var.cloudflare_nsg_deny_https_priority
      source_port_range          = local.nsg_any_port_range
      destination_port_range     = var.cloudflare_nsg_https_port
      source_address_prefix      = local.nsg_internet_prefix
      destination_address_prefix = local.nsg_any_address
    }
    deny_internet_http = {
      name                       = "DenyInternetHTTPInbound"
      access                     = local.nsg_access_deny
      direction                  = local.nsg_direction_inbound
      protocol                   = var.cloudflare_nsg_protocol
      priority                   = var.cloudflare_nsg_deny_http_priority
      source_port_range          = local.nsg_any_port_range
      destination_port_range     = var.cloudflare_nsg_http_port
      source_address_prefix      = local.nsg_internet_prefix
      destination_address_prefix = local.nsg_any_address
    }
  }
}
