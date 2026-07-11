variable "name" {
  type        = string
  description = "Name of the budget. Caller decides the naming convention (typically <prefix><resource_group_name>)."
  nullable    = false
}

variable "resource_group_id" {
  type        = string
  description = "Resource ID of the resource group the budget is scoped to."
  nullable    = false
}

variable "amount" {
  type        = number
  description = "Budget amount in the subscription's default currency. Set to 0 (or negative) to disable the resource entirely (the module becomes a no-op)."
  nullable    = false
}

variable "time_grain" {
  type        = string
  description = "Billing period the budget tracks."
  default     = "Monthly"
  nullable    = false

  validation {
    condition     = contains(["Monthly", "Quarterly", "Annually", "BillingMonth", "BillingQuarter", "BillingAnnual"], var.time_grain)
    error_message = "time_grain must be one of: Monthly, Quarterly, Annually, BillingMonth, BillingQuarter, BillingAnnual."
  }
}

variable "start_date" {
  type        = string
  description = "Budget start date in RFC3339 format. Azure requires the first day of a month and rejects changes once the budget exists (the module ignores time_period drift)."
  nullable    = false
}

variable "notification_thresholds" {
  type        = list(number)
  description = "Actual-spend percentage thresholds that trigger notifications (e.g. [50, 80, 100])."
  default     = [80, 100]
  nullable    = false

  validation {
    condition     = alltrue([for t in var.notification_thresholds : t > 0 && t <= 1000])
    error_message = "Each notification threshold must be > 0 and <= 1000."
  }
}

variable "notification_enabled" {
  type        = bool
  description = "Whether the actual-spend notifications are enabled."
  default     = true
  nullable    = false
}

variable "notification_operator" {
  type        = string
  description = "Comparison operator for thresholds."
  default     = "GreaterThan"
  nullable    = false

  validation {
    condition     = contains(["EqualTo", "GreaterThan", "GreaterThanOrEqualTo"], var.notification_operator)
    error_message = "notification_operator must be one of: EqualTo, GreaterThan, GreaterThanOrEqualTo."
  }
}

variable "actual_threshold_type" {
  type        = string
  description = "Threshold type for the actual-spend notifications."
  default     = "Actual"
  nullable    = false

  validation {
    condition     = contains(["Actual", "Forecasted"], var.actual_threshold_type)
    error_message = "actual_threshold_type must be Actual or Forecasted."
  }
}

variable "forecasted_notification_enabled" {
  type        = bool
  description = "Whether the forecasted-spend notification is enabled."
  default     = true
  nullable    = false
}

variable "forecasted_threshold_percent" {
  type        = number
  description = "Threshold percentage for the forecasted-spend notification."
  default     = 100
  nullable    = false

  validation {
    condition     = var.forecasted_threshold_percent > 0 && var.forecasted_threshold_percent <= 1000
    error_message = "forecasted_threshold_percent must be > 0 and <= 1000."
  }
}

variable "forecasted_threshold_type" {
  type        = string
  description = "Threshold type for the forecasted-spend notification."
  default     = "Forecasted"
  nullable    = false

  validation {
    condition     = contains(["Actual", "Forecasted"], var.forecasted_threshold_type)
    error_message = "forecasted_threshold_type must be Actual or Forecasted."
  }
}

variable "contact_emails" {
  type        = list(string)
  description = "Email addresses to notify when a threshold is hit. Caller is responsible for the fallback chain (e.g. operator email when no overrides are set)."
  nullable    = false

  validation {
    condition     = length(var.contact_emails) > 0
    error_message = "contact_emails must contain at least one address."
  }
}
