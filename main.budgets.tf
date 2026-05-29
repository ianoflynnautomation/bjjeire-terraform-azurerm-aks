locals {
  budget_contact_emails = length(var.budget_notification_emails) > 0 ? var.budget_notification_emails : [var.private_email]
}

module "budget" {
  source = "./modules/budget"

  name              = "${var.budget_name_prefix}${var.resource_group_name}"
  resource_group_id = azurerm_resource_group.rg.id
  amount            = var.budget_amount
  time_grain        = var.budget_time_grain
  start_date        = var.budget_start_date

  notification_thresholds         = var.budget_notification_thresholds
  notification_enabled            = var.budget_notification_enabled
  notification_operator           = var.budget_notification_operator
  actual_threshold_type           = var.budget_actual_threshold_type
  forecasted_notification_enabled = var.budget_forecasted_notification_enabled
  forecasted_threshold_percent    = var.budget_forecasted_threshold_percent
  forecasted_threshold_type       = var.budget_forecasted_threshold_type
  contact_emails                  = local.budget_contact_emails
}

moved {
  from = azurerm_consumption_budget_resource_group.rg
  to   = module.budget.azurerm_consumption_budget_resource_group.this
}
