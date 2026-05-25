variable "storage_images_account_name" {
  type        = string
  description = "Name of the storage account for gym/event images. Globally unique, 3-24 lowercase alphanumeric chars."
  nullable    = false

  validation {
    condition = (
      length(var.storage_images_account_name) >= 3
      && length(var.storage_images_account_name) <= 24
      && lower(var.storage_images_account_name) == var.storage_images_account_name
    )
    error_message = "storage_images_account_name must be 3-24 lowercase characters. Azure also requires globally unique alphanumeric names."
  }
}

variable "storage_images_replication_type" {
  type        = string
  description = "Replication type for the images storage account (LRS, ZRS, GRS)."
  default     = "LRS"
  nullable    = false

  validation {
    condition     = contains(["LRS", "ZRS", "GRS"], var.storage_images_replication_type)
    error_message = "storage_images_replication_type must be one of: LRS, ZRS, GRS."
  }
}

variable "storage_images_account_tier" {
  type        = string
  description = "Performance tier for the images storage account (Standard or Premium)."
  default     = "Standard"
  nullable    = false

  validation {
    condition     = contains(["Standard", "Premium"], var.storage_images_account_tier)
    error_message = "storage_images_account_tier must be Standard or Premium."
  }
}

variable "storage_images_allow_nested_items_to_be_public" {
  type        = bool
  description = "Allow individual blobs/containers inside the account to be made public. Keep false for image storage; CORS + Cloudflare handle delivery."
  default     = false
  nullable    = false
}

variable "storage_images_public_network_access_enabled" {
  type        = bool
  description = "Whether the storage account is reachable from the public internet. Required true while Cloudflare proxies blob reads; flip to false once a private endpoint is in place."
  default     = true
  nullable    = false
}

variable "storage_images_https_traffic_only_enabled" {
  type        = bool
  description = "Reject non-HTTPS requests at the storage account boundary."
  default     = true
  nullable    = false
}

variable "storage_images_min_tls_version" {
  type        = string
  description = "Minimum TLS version accepted by the storage account (TLS1_2 or TLS1_3)."
  default     = "TLS1_2"
  nullable    = false

  validation {
    condition     = contains(["TLS1_2", "TLS1_3"], var.storage_images_min_tls_version)
    error_message = "storage_images_min_tls_version must be TLS1_2 or TLS1_3."
  }
}

variable "storage_images_shared_access_key_enabled" {
  type        = bool
  description = "Allow account-key auth on the storage account. Keep false — workloads use the workload identities provisioned via role_assignments."
  default     = false
  nullable    = false
}

variable "storage_images_blob_cors_allowed_headers" {
  type        = list(string)
  description = "CORS allowed_headers for the images blob service."
  default     = ["*"]
  nullable    = false

  validation {
    condition     = length(var.storage_images_blob_cors_allowed_headers) > 0
    error_message = "storage_images_blob_cors_allowed_headers must contain at least one entry."
  }
}

variable "storage_images_blob_cors_allowed_methods" {
  type        = list(string)
  description = "CORS allowed_methods for the images blob service."
  default     = ["GET", "HEAD"]
  nullable    = false

  validation {
    condition = length(var.storage_images_blob_cors_allowed_methods) > 0 && alltrue([
      for method in var.storage_images_blob_cors_allowed_methods :
      contains(["DELETE", "GET", "HEAD", "MERGE", "OPTIONS", "POST", "PUT"], method)
    ])
    error_message = "storage_images_blob_cors_allowed_methods must be non-empty and only contain valid Azure Storage CORS methods (DELETE, GET, HEAD, MERGE, OPTIONS, POST, PUT)."
  }
}

variable "storage_images_blob_cors_exposed_headers" {
  type        = list(string)
  description = "CORS exposed_headers for the images blob service."
  default     = ["ETag", "Content-Length", "Content-Type"]
  nullable    = false
}

variable "storage_images_blob_cors_max_age_seconds" {
  type        = number
  description = "CORS max_age_in_seconds for the images blob service."
  default     = 86400
  nullable    = false

  validation {
    condition     = var.storage_images_blob_cors_max_age_seconds >= 0
    error_message = "storage_images_blob_cors_max_age_seconds must be non-negative."
  }
}

variable "storage_images_cors_origins" {
  type        = list(string)
  description = "Allowed CORS origins for blob reads. Set to your Cloudflare-proxied domain(s) in production."
  default     = ["*"]
  nullable    = false

  validation {
    condition = length(var.storage_images_cors_origins) > 0 && alltrue([
      for origin in var.storage_images_cors_origins :
      origin == "*" || startswith(origin, "https://") || startswith(origin, "http://localhost") || startswith(origin, "http://127.0.0.1")
    ])
    error_message = "storage_images_cors_origins must contain at least one origin and each origin must be *, HTTPS, localhost, or 127.0.0.1."
  }
}

variable "storage_images_containers" {
  type = map(object({
    name          = string
    public_access = optional(string, "None")
  }))
  description = "Blob containers created in the images storage account."
  default = {
    images = {
      name          = "images"
      public_access = "None"
    }
  }
  nullable = false

  validation {
    condition = alltrue([
      for container in values(var.storage_images_containers) :
      length(trimspace(container.name)) > 0
      && contains(["None", "Blob", "Container"], container.public_access)
    ])
    error_message = "Each storage_images_containers entry must have a non-empty name and public_access of None, Blob, or Container."
  }
}

variable "storage_images_role_definition_api" {
  type        = string
  description = "Azure RBAC role assigned to the api workload identity on the images storage account."
  default     = "Storage Blob Data Reader"
  nullable    = false

  validation {
    condition     = length(trimspace(var.storage_images_role_definition_api)) > 0
    error_message = "storage_images_role_definition_api must be a non-empty string."
  }
}

variable "storage_images_role_definition_seeder" {
  type        = string
  description = "Azure RBAC role assigned to the seeder workload identity on the images storage account."
  default     = "Storage Blob Data Contributor"
  nullable    = false

  validation {
    condition     = length(trimspace(var.storage_images_role_definition_seeder)) > 0
    error_message = "storage_images_role_definition_seeder must be a non-empty string."
  }
}
