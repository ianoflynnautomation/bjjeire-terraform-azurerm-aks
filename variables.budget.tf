variable "budget_amount" {
  type        = number
  default     = 0
  description = "Monthly Azure cost budget for the resource group, in the subscription's billing currency. Set to 0 to disable the budget (no resource is created)."
}

variable "budget_name_prefix" {
  type        = string
  default     = "budget-"
  description = "Prefix for the consumption budget resource name. Final name: <prefix><resource_group_name>."
}

variable "budget_time_grain" {
  type        = string
  default     = "Monthly"
  description = "Budget cycle: Monthly, Quarterly, or Annually. Determines when totals reset."

  validation {
    condition     = contains(["Monthly", "Quarterly", "Annually", "BillingMonth", "BillingQuarter", "BillingAnnual"], var.budget_time_grain)
    error_message = "budget_time_grain must be one of: Monthly, Quarterly, Annually, BillingMonth, BillingQuarter, BillingAnnual."
  }
}

variable "budget_start_date" {
  type        = string
  default     = null
  description = "Budget start date in RFC3339 format. Must be the first day of the CURRENT month or a future month — Azure rejects past start dates on create. When null, the module defaults to the first of the current month (computed at plan time). Once the budget exists Azure rejects changes; the module ignores time_period drift."
}

variable "budget_notification_thresholds" {
  type        = list(number)
  default     = [50, 80, 100]
  description = "Actual-spend thresholds (percent of budget_amount) that trigger email notifications. A 100% forecasted-spend notification is always added on top of these."
}

variable "budget_notification_enabled" {
  type        = bool
  default     = true
  description = "Enable email notifications on the dynamic per-percent actual-spend thresholds. Set false to keep the budget tracking spend without alerts."
}

variable "budget_notification_operator" {
  type        = string
  default     = "GreaterThan"
  description = "Comparison used against each threshold percent. Allowed: GreaterThan, GreaterThanOrEqualTo, EqualTo."

  validation {
    condition     = contains(["GreaterThan", "GreaterThanOrEqualTo", "EqualTo"], var.budget_notification_operator)
    error_message = "budget_notification_operator must be one of: GreaterThan, GreaterThanOrEqualTo, EqualTo."
  }
}

variable "budget_actual_threshold_type" {
  type        = string
  default     = "Actual"
  description = "Threshold type for the dynamic per-percent notification block. Allowed: Actual, Forecasted."

  validation {
    condition     = contains(["Actual", "Forecasted"], var.budget_actual_threshold_type)
    error_message = "budget_actual_threshold_type must be Actual or Forecasted."
  }
}

variable "budget_forecasted_notification_enabled" {
  type        = bool
  default     = true
  description = "Enable the always-on forecasted-spend notification. Independent of budget_notification_enabled."
}

variable "budget_forecasted_threshold_percent" {
  type        = number
  default     = 100
  description = "Percent threshold for the always-on forecasted-spend notification (100 = projected to hit budget by cycle end)."
}

variable "budget_forecasted_threshold_type" {
  type        = string
  default     = "Forecasted"
  description = "Threshold type for the second always-on notification block. Kept overridable for completeness; only Forecasted is meaningful for the look-ahead alert."

  validation {
    condition     = contains(["Actual", "Forecasted"], var.budget_forecasted_threshold_type)
    error_message = "budget_forecasted_threshold_type must be Actual or Forecasted."
  }
}

variable "budget_notification_emails" {
  type        = list(string)
  default     = []
  description = "Recipients for budget threshold notifications. Falls back to [private_email] when empty."
}
