
variable "storage_images_account_name" {
  type        = string
  description = "Name of the storage account for gym/event images. Globally unique, 3-24 lowercase alphanumeric chars."
}

variable "storage_images_replication_type" {
  type        = string
  description = "Replication type for the images storage account (LRS, ZRS, GRS)."
  default     = "LRS"
}

variable "storage_images_cors_origins" {
  type        = list(string)
  description = "Allowed CORS origins for blob reads. Set to your Cloudflare-proxied domain(s) in production."
  default     = ["*"]
}
