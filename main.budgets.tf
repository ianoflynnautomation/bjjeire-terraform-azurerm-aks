locals {
  budget_contact_emails = length(var.budget_notification_emails) > 0 ? var.budget_notification_emails : [var.private_email]
}

resource "azurerm_consumption_budget_resource_group" "rg" {
  count             = var.budget_amount > 0 ? 1 : 0
  name              = "${var.budget_name_prefix}${var.resource_group_name}"
  resource_group_id = azurerm_resource_group.rg.id

  amount     = var.budget_amount
  time_grain = var.budget_time_grain

  time_period {
    start_date = var.budget_start_date
  }

  dynamic "notification" {
    for_each = var.budget_notification_thresholds
    content {
      enabled        = var.budget_notification_enabled
      threshold      = notification.value
      operator       = var.budget_notification_operator
      threshold_type = var.budget_actual_threshold_type
      contact_emails = local.budget_contact_emails
    }
  }

  notification {
    enabled        = var.budget_forecasted_notification_enabled
    threshold      = var.budget_forecasted_threshold_percent
    operator       = var.budget_notification_operator
    threshold_type = var.budget_forecasted_threshold_type
    contact_emails = local.budget_contact_emails
  }

  lifecycle {
    # Azure rejects start_date changes once the budget exists; ignore so the
    # next plan after month rollover doesn't try to update it.
    ignore_changes = [time_period]
  }
}
