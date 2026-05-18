variable "aks_admin_group_display_names" {
  type        = list(string)
  description = "Display names of Entra ID security groups granted AKS admin (cluster-admin via Azure RBAC for Kubernetes)."
  default     = []
}

variable "oauth2_proxy_allowed_group_display_name" {
  type        = string
  description = "Display name of the Entra ID security group whose members are allowed past the oauth2-proxy. Empty string disables the lookup."
  default     = ""
}

data "azuread_group" "aks_admins" {
  for_each         = toset(var.aks_admin_group_display_names)
  display_name     = each.value
  security_enabled = true
}

data "azuread_group" "oauth2_proxy_allowed" {
  count            = var.oauth2_proxy_allowed_group_display_name == "" ? 0 : 1
  display_name     = var.oauth2_proxy_allowed_group_display_name
  security_enabled = true
}

locals {
  aks_admin_group_object_ids = [
    for g in data.azuread_group.aks_admins : g.object_id
  ]

  oauth2_proxy_allowed_group_id = (
    length(data.azuread_group.oauth2_proxy_allowed) == 0
    ? ""
    : data.azuread_group.oauth2_proxy_allowed[0].object_id
  )
}
