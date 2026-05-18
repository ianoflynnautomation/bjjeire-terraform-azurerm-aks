variable "name" {
  type        = string
  description = "The name of the user assigned identity."
  nullable    = false

  validation {
    condition     = length(var.name) >= 3 && length(var.name) <= 128
    error_message = "name must be between 3 and 128 characters long."
  }
}

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group in which to create the user assigned identity."
  nullable    = false
}

variable "location" {
  type        = string
  description = "The Azure region where the user assigned identity should be created."
  nullable    = false
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "A mapping of tags to assign to the resource."
  nullable    = false
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

  validation {
    condition = alltrue([
      for credential in values(var.federated_identity_credentials) :
      length(credential.audience) > 0
      && alltrue([for audience in credential.audience : length(trimspace(audience)) > 0])
      && startswith(credential.issuer, "https://")
      && length(trimspace(credential.name)) > 0
      && length(trimspace(credential.subject)) > 0
    ])
    error_message = "Each federated_identity_credentials entry must have a non-empty audience, HTTPS issuer, name, and subject."
  }
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

  validation {
    condition = alltrue([
      for assignment in values(var.role_assignments) :
      length(trimspace(assignment.role_definition_id_or_name)) > 0
      && length(trimspace(assignment.scope)) > 0
      && (assignment.condition_version == null || assignment.condition_version == "2.0")
    ])
    error_message = "Each role_assignments entry must have a non-empty role_definition_id_or_name and scope; condition_version, when set, must be 2.0."
  }
}
