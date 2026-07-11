resource "azurerm_consumption_budget_resource_group" "this" {
  count = var.amount > 0 ? 1 : 0

  name              = var.name
  resource_group_id = var.resource_group_id

  amount     = var.amount
  time_grain = var.time_grain

  time_period {
    start_date = var.start_date
  }

  dynamic "notification" {
    for_each = var.notification_thresholds
    content {
      enabled        = var.notification_enabled
      threshold      = notification.value
      operator       = var.notification_operator
      threshold_type = var.actual_threshold_type
      contact_emails = var.contact_emails
    }
  }

  notification {
    enabled        = var.forecasted_notification_enabled
    threshold      = var.forecasted_threshold_percent
    operator       = var.notification_operator
    threshold_type = var.forecasted_threshold_type
    contact_emails = var.contact_emails
  }

  lifecycle {
    # Azure rejects start_date changes once the budget exists; ignore so the
    # next plan after month rollover doesn't try to update it.
    ignore_changes = [time_period]
  }
}
