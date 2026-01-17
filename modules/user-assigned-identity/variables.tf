variable "name" {
  type        = string
  description = "The name of the user assigned identity."

  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9_-]{2,127}$", var.name))
    error_message = "The name must start with a letter or number, be between 3 and 128 characters long, and can only contain alphanumerics, hyphens, and underscores."
  }
}

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group in which to create the user assigned identity."
}

variable "location" {
  type        = string
  description = "The Azure region where the user assigned identity should be created."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "A mapping of tags to assign to the resource."
}

variable "federated_identity_credentials" {
  type = map(object({
    audience = list(string)
    issuer   = string
    name     = string
    subject  = string
  }))
  default     = {}
  description = <<-EOT
  A map of federated identity credentials to create on the user assigned identity. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

  - `audience` - (Required) Specifies the audience for this Federated Identity Credential.
  - `issuer` - (Required) Specifies the issuer of this Federated Identity Credential.
  - `name` - (Required) Specifies the name of this Federated Identity Credential. Changing this forces a new resource to be created.
  - `subject` - (Required) Specifies the subject for this Federated Identity Credential.
  EOT
  nullable    = false
}

variable "role_assignments" {
  type = map(object({
    role_definition_id_or_name             = string
    scope                                  = string
    condition                              = optional(string, null)
    condition_version                      = optional(string, null)
    delegated_managed_identity_resource_id = optional(string, null)
    description                            = optional(string, null)
    skip_service_principal_aad_check       = optional(bool, null)
  }))
  default     = {}
  description = <<-EOT
  A map of role assignments to create for the user assigned identity. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

  - `role_definition_id_or_name` - The ID or name of the role definition to assign to the principal.
  - `scope` - The ID of the scope to assign the role to.
  - `condition` - (Optional) The condition which will be used to scope the role assignment.
  - `condition_version` - (Optional) The version of the condition syntax. Leave as `null` if you are not using a condition, if you are then valid values are '2.0'.
  - `delegated_managed_identity_resource_id` - (Optional) The delegated Azure Resource Id which contains a Managed Identity. Changing this forces a new resource to be created. This field is only used in cross-tenant scenario.
  - `description` - (Optional) The description of the role assignment.
  - `skip_service_principal_aad_check` - (Optional) Skip validating the Service Principal in AAD before applying the Role Assignment. Defaults to `false`. Changing this forces a new resource to be created.
  EOT
  nullable    = false
}
