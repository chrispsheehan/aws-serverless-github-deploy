### start of static vars set in root.hcl ###
variable "project_name" {
  type        = string
  description = "Project name used in naming resources"
}

variable "environment" {
  type        = string
  description = "Environment reference used in naming resources i.e. 'dev'"
}

variable "lambda_bucket" {
  type        = string
  description = "Lambda bucket where the code zip(s) are uploaded to"
}
### end of static vars set in root.hcl ###


### start of dynamic vars required for resources ###
variable "lambda_name" {
  type        = string
  description = "Must match the name of the zip - formed in /backend directory i.e. /backend/api = 'api'"
}

variable "lambda_version" {
  type        = string
  description = "Lambda code version to be deployed. Used in locating zip file keys"
}
### end of dynamic vars required for resources ###


variable "log_retention_days" {
  type        = number
  description = "Number of days to hold logs"
  default     = 1
}

variable "deployment_config" {
  description = "Traffic shifting: all_at_once | canary | linear"
  type = object({
    strategy         = string           # all_at_once | canary | linear
    percentage       = optional(number) # 1..99 (req for canary/linear)
    interval_minutes = optional(number) # >=1  (req for canary/linear)
  })
  default = { strategy = "all_at_once" }

  validation {
    condition = (
      contains(["all_at_once", "canary", "linear"], var.deployment_config.strategy)
      &&
      (
        var.deployment_config.strategy == "all_at_once"
        ||
        (
          coalesce(var.deployment_config.percentage, 0) >= 1
          && coalesce(var.deployment_config.percentage, 0) <= 99
          && coalesce(var.deployment_config.interval_minutes, 0) >= 1
        )
      )
    )
    error_message = "Use strategy all_at_once | canary | linear. For canary/linear, set percentage (1..99) and interval_minutes (>=1)."
  }
}

variable "provisioned_config_defaults" {
  description = "Fall back values for provisioned_config.auto_scale.trigger_percent and provisioned_config.auto_scale.cool_down_seconds"
  type = object({
    trigger_percent   = number
    cool_down_seconds = number
  })
  default = {
    trigger_percent   = 70
    cool_down_seconds = 60
  }
}

variable "provisioned_config" {
  description = "Either fixed provisioned concurrency (fixed) or autoscaled (auto_scale); omit/zero = none"
  type = object({
    fixed    = optional(number) # 0/omit = off, >0 = fixed PC
    reserved = optional(number) # 0/omit = unreserved, >0 = reserved

    auto_scale = optional(object({
      min               = number
      max               = number
      trigger_percent   = optional(number)
      cool_down_seconds = optional(number)
    }))
  })
  default = {
    fixed    = 0
    reserved = 1
    # auto_scale = {
    #   max               = 1,
    #   min               = 0,
    #   trigger_percent   = 70
    #   cool_down_seconds = 60
    # }
  }

  validation {
    condition = (
      var.provisioned_config.fixed == null
      ? true
      : var.provisioned_config.reserved > var.provisioned_config.fixed
    )
    error_message = "When provisioned_config.fixed is set, provisioned_config.reserved must be greater than fixed to avoid Lambda throttling."
  }

  validation {
    condition = !(
      (var.provisioned_config.fixed != null) &&
      (var.provisioned_config.auto_scale != null)
    )
    error_message = "Specify either 'fixed' or 'auto_scale' (or neither), not both."
  }

  # When autoscale is set, ensure max > min
  validation {
    condition = (
      var.provisioned_config.auto_scale != null
      ? (var.provisioned_config.auto_scale.max > var.provisioned_config.auto_scale.min)
      : true
    )
    error_message = "When auto_scale is set, 'max' must be greater than 'min'."
  }

  # When autoscale.trigger_percent is set, ensure is 1-99
  validation {
    condition = (
      var.provisioned_config.auto_scale != null
      ? (var.provisioned_config.auto_scale.trigger_percent > 0 && var.provisioned_config.auto_scale.trigger_percent < 100)
      : true
    )
    error_message = "When autoscale.trigger_percent, must be > 0 && < 100"
  }

  # When autoscale.cool_down_seconds is set, ensure is at least a minute, max and hour
  validation {
    condition = (
      var.provisioned_config.auto_scale != null
      ? (var.provisioned_config.auto_scale.cool_down_seconds > 59 && var.provisioned_config.auto_scale.cool_down_seconds < 3600)
      : true
    )
    error_message = "When autoscale.cool_down_seconds, must be > 59 && < 3600"
  }
}