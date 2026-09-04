variable "storage_atest_account_name" {
  type        = string
  description = <<-EOT
  Name of the storage account holding the atest run-history database. Globally
  unique, 3-24 lowercase alphanumeric chars.

  EMPTY DISABLES THE FEATURE ENTIRELY — no storage account, no identity. The
  root module is shared by every environment, so a required variable here would
  have broken `terraform plan` in staging and prod the moment dev opted in.
  Opting in is per-environment, by setting this in that environment's tfvars.
  EOT
  default     = ""
  nullable    = false

  validation {
    condition = var.storage_atest_account_name == "" || (
      length(var.storage_atest_account_name) >= 3
      && length(var.storage_atest_account_name) <= 24
      && lower(var.storage_atest_account_name) == var.storage_atest_account_name
    )
    error_message = "storage_atest_account_name must be empty (feature disabled) or 3-24 lowercase characters. Azure also requires globally unique alphanumeric names."
  }
}

variable "storage_atest_account_tier" {
  type        = string
  description = "Performance tier for the atest history storage account."
  default     = "Standard"
  nullable    = false

  validation {
    condition     = contains(["Standard", "Premium"], var.storage_atest_account_tier)
    error_message = "storage_atest_account_tier must be Standard or Premium."
  }
}

variable "storage_atest_replication_type" {
  type        = string
  description = "Replication type for the atest history storage account. LRS is the default because the contents are derived data, rebuildable by replaying CI runs."
  default     = "LRS"
  nullable    = false

  validation {
    condition     = contains(["LRS", "ZRS", "GRS"], var.storage_atest_replication_type)
    error_message = "storage_atest_replication_type must be one of: LRS, ZRS, GRS."
  }
}

variable "storage_atest_min_tls_version" {
  type        = string
  description = "Minimum TLS version accepted by the atest history storage account."
  default     = "TLS1_2"
  nullable    = false

  validation {
    condition     = contains(["TLS1_0", "TLS1_1", "TLS1_2"], var.storage_atest_min_tls_version)
    error_message = "storage_atest_min_tls_version must be one of: TLS1_0, TLS1_1, TLS1_2."
  }
}

variable "storage_atest_retention_days" {
  type        = number
  description = <<-EOT
  Days after which a run record is deleted by the account's lifecycle policy.

  Deliberately LONGER than atest's read window (default 90 days, `?window=` on
  the history URL). The window decides what gets scored; this decides what is
  paid for. Setting it below the window would let the account delete records
  the analysis was about to read, which shows up as a flake score quietly
  moving rather than as an error.

  This is the backstop, not the primary control — `atest history prune` runs on
  main and does the same job. It exists because a repo that stops merging, or a
  workflow disabled while something else is debugged, would otherwise accrue
  history nobody reads.
  EOT
  default     = 120
  nullable    = false

  validation {
    condition     = var.storage_atest_retention_days >= 1 && var.storage_atest_retention_days <= 99999
    error_message = "storage_atest_retention_days must be between 1 and 99999 (Azure lifecycle management limits)."
  }
}

variable "storage_atest_soft_delete_days" {
  type        = number
  description = <<-EOT
  Days a deleted run record can still be undeleted.

  Covers one specific mistake: a mistyped `atest history prune --keep-days 1`
  removes months of history in a single call, and unlike an overwrite that is
  not something the pipeline will rebuild. Blob versioning is deliberately OFF
  on this account for the opposite reason — see main.storage-atest.tf.
  EOT
  default     = 7
  nullable    = false

  validation {
    condition     = var.storage_atest_soft_delete_days >= 1 && var.storage_atest_soft_delete_days <= 365
    error_message = "storage_atest_soft_delete_days must be between 1 and 365."
  }
}

variable "storage_atest_containers" {
  type = map(object({
    name          = string
    public_access = optional(string, "None")
  }))
  description = "Blob containers created in the atest history storage account. atest writes run records as one object per run and shard under <container>/v1/runs/<date>/, so one container holds the whole history."
  default = {
    atest-history = {
      name          = "atest-history"
      public_access = "None"
    }
  }
  nullable = false

  validation {
    condition = alltrue([
      for container in values(var.storage_atest_containers) :
      length(trimspace(container.name)) > 0
      && container.public_access == "None"
    ])
    error_message = "Each storage_atest_containers entry must have a non-empty name and public_access of None. Run history is not public data."
  }
}

variable "storage_atest_role_definition_writer" {
  type        = string
  description = "Azure RBAC role granted to the main-branch-only CI identity on the atest history account. This is the sole principal permitted to write history."
  default     = "Storage Blob Data Contributor"
  nullable    = false
}

variable "storage_atest_role_definition_reader" {
  type        = string
  description = "Azure RBAC role granted to the pull-request CI identity. Read-only by design: a pull request scores against the trunk baseline but must not amend it."
  default     = "Storage Blob Data Reader"
  nullable    = false
}
