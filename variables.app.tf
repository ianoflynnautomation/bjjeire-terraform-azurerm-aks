variable "donation_bitcoin_address" {
  type        = string
  description = "Donation bitcoin address"
  default     = null
  sensitive   = true
}

variable "mongodb_root_password_length" {
  type        = number
  default     = 32
  description = "Total length of the generated MongoDB root password. With 32 alphanumeric chars (62^32 ≈ 2.27e57 possibilities) entropy is already far past any complexity requirement, which is why special chars are off by default."
}

variable "mongodb_root_password_special" {
  type        = bool
  default     = false
  description = "Whether to include override_special characters in the generated password. Default false — the password is embedded into a Mongo URI (mongodb://admin:<password>@host/db) where any URI-reserved char in the password causes parse failures (e.g. invalid '%' escape, premature '@' host split). Set true only with an override_special restricted to URI-unreserved characters (see validation on mongodb_root_password_override_special)."
}

variable "mongodb_root_password_min_lower" {
  type        = number
  default     = 2
  description = "Minimum lowercase letters required in the generated password."
}

variable "mongodb_root_password_min_upper" {
  type        = number
  default     = 2
  description = "Minimum uppercase letters required in the generated password."
}

variable "mongodb_root_password_min_numeric" {
  type        = number
  default     = 2
  description = "Minimum digits required in the generated password."
}

variable "mongodb_root_password_min_special" {
  type        = number
  default     = 0
  description = "Minimum special characters required in the generated password. Defaults to 0 since special chars are off by default; raise only if mongodb_root_password_special is true."
}

variable "mongodb_root_password_override_special" {
  type        = string
  default     = "-._~"
  description = "Allowed special-character set when mongodb_root_password_special is true. Restricted to RFC 3986 unreserved characters (- . _ ~) so the password is always safe to embed in a Mongo connection URI without percent-encoding. Any other character (especially : / ? # [ ] @ % & = + and shell metacharacters) is rejected by validation — DO NOT add them; they will silently break MongoConfigurationException parsing or worse, mis-route auth."

  validation {
    condition     = can(regex("^[A-Za-z0-9._~-]*$", var.mongodb_root_password_override_special))
    error_message = "mongodb_root_password_override_special may only contain URI-unreserved characters: alphanumerics and any of '-', '.', '_', '~'. URI-reserved characters (: / ? # [ ] @ ! $ & ' ( ) * + , ; = %) corrupt the Mongo connection string when the generated password contains them."
  }
}
