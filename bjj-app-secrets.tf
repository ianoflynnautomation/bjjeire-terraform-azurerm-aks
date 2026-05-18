resource "random_password" "bjj_mongodb_root_password" {
  length           = 32
  special          = true
  min_lower        = 2
  min_upper        = 2
  min_numeric      = 2
  min_special      = 2
  override_special = "!@#%*-_=+"

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
