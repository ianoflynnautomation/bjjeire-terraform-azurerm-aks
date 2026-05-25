resource "random_password" "bjj_mongodb_root_password" {
  length           = var.mongodb_root_password_length
  special          = var.mongodb_root_password_special
  min_lower        = var.mongodb_root_password_min_lower
  min_upper        = var.mongodb_root_password_min_upper
  min_numeric      = var.mongodb_root_password_min_numeric
  min_special      = var.mongodb_root_password_min_special
  override_special = var.mongodb_root_password_override_special

  lifecycle {
    ignore_changes = [
      length,
      special,
      min_lower,
      min_upper,
      min_numeric,
      min_special,
      override_special,
    ]
  }
}
