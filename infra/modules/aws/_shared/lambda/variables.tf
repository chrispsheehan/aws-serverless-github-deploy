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
### end of dynamic vars required for resources ###


variable "log_retention_days" {
  type        = number
  description = "Number of days to hold logs"
  default     = 1
}

variable "additional_policy_arns" {
  description = "List of IAM policy ARNs to attach to the role"
  type        = list(string)
  default     = []
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

variable "provisioned_config" {
  description = "Either fixed provisioned concurrency (fixed) or autoscaled (auto_scale); omit/zero = none"
  type = object({
    fixed                = optional(number) # 0/omit = off, >0 = fixed PC
    reserved_concurrency = optional(number) # 0/omit = no concurrency limit, >0 = limited concurrency

    auto_scale = optional(object({
      min                        = number
      max                        = number
      trigger_percent            = optional(number)
      scale_in_cooldown_seconds  = optional(number)
      scale_out_cooldown_seconds = optional(number)
    }))

    sqs_scale = optional(object({
      min                        = number
      max                        = number
      visible_messages           = number
      queue_name                 = optional(string)
      scale_in_cooldown_seconds  = optional(number)
      scale_out_cooldown_seconds = optional(number)
    }))
  })
  default = {
    fixed                = 0
    reserved_concurrency = 1
  }

  validation {
    condition = (
      var.provisioned_config.fixed == null || var.provisioned_config.fixed == 0
      ? true
      : (
        var.provisioned_config.reserved_concurrency != null &&
        var.provisioned_config.reserved_concurrency > var.provisioned_config.fixed
      )
    )
    error_message = "When provisioned_config.fixed > 0, provisioned_config.reserved_concurrency must be set and greater than fixed to avoid Lambda throttling."
  }

  validation {
    condition = !(
      (
        coalesce(var.provisioned_config.fixed, 0) > 0
        ) && (
        var.provisioned_config.auto_scale != null ||
        var.provisioned_config.sqs_scale != null
      )
      ) && !(
      var.provisioned_config.auto_scale != null &&
      var.provisioned_config.sqs_scale != null
    )
    error_message = "Specify only one of 'fixed', 'auto_scale', or 'sqs_scale' (or none)."
  }

  validation {
    condition = (
      (
        var.provisioned_config.auto_scale != null
        ? var.provisioned_config.auto_scale.max > var.provisioned_config.auto_scale.min
        : true
      )
      &&
      (
        var.provisioned_config.sqs_scale != null
        ? var.provisioned_config.sqs_scale.max > var.provisioned_config.sqs_scale.min
        : true
      )
    )
    error_message = "When auto_scale or sqs_scale is set, 'max' must be greater than 'min'."
  }

  validation {
    condition = (
      var.provisioned_config.auto_scale != null
      ? (var.provisioned_config.auto_scale.trigger_percent > 0 && var.provisioned_config.auto_scale.trigger_percent < 100)
      : true
    )
    error_message = "When autoscale.trigger_percent, must be > 0 && < 100"
  }

  validation {
    condition = (
      var.provisioned_config.auto_scale != null
      ? (
        var.provisioned_config.auto_scale.scale_in_cooldown_seconds != null &&
        var.provisioned_config.auto_scale.scale_out_cooldown_seconds != null &&

        var.provisioned_config.auto_scale.scale_in_cooldown_seconds >= 60 &&
        var.provisioned_config.auto_scale.scale_out_cooldown_seconds >= 60
      )
      : true
    )
    error_message = "When auto_scale is set, both scale_in_cooldown_seconds and scale_out_cooldown_seconds must be specified and each must be at least 60 seconds."
  }

  validation {
    condition = (
      var.provisioned_config.sqs_scale != null
      ? (
        var.provisioned_config.sqs_scale.min >= 0 &&
        var.provisioned_config.sqs_scale.max > var.provisioned_config.sqs_scale.min &&
        floor(var.provisioned_config.sqs_scale.min) == var.provisioned_config.sqs_scale.min &&
        floor(var.provisioned_config.sqs_scale.max) == var.provisioned_config.sqs_scale.max
      )
      : true
    )
    error_message = "When sqs_scale is set, 'min' must be an integer >= 0 and 'max' must be an integer greater than 'min'."
  }

  validation {
    condition = (
      var.provisioned_config.sqs_scale != null
      ? (
        var.provisioned_config.sqs_scale.visible_messages > 0 &&
        floor(var.provisioned_config.sqs_scale.visible_messages) == var.provisioned_config.sqs_scale.visible_messages
      )
      : true
    )
    error_message = "When sqs_scale is set, 'visible_messages' must be a positive integer."
  }

  validation {
    condition = (
      var.provisioned_config.sqs_scale != null && var.provisioned_config.sqs_scale.queue_name != null
      ? length(trimspace(var.provisioned_config.sqs_scale.queue_name)) > 0
      : true
    )
    error_message = "When sqs_scale.queue_name is set, it must be a non-empty string."
  }

  validation {
    condition = (
      var.provisioned_config.sqs_scale != null
      ? (
        var.provisioned_config.sqs_scale.scale_in_cooldown_seconds != null &&
        var.provisioned_config.sqs_scale.scale_out_cooldown_seconds != null &&

        var.provisioned_config.sqs_scale.scale_in_cooldown_seconds >= 60 &&
        var.provisioned_config.sqs_scale.scale_out_cooldown_seconds >= 60
      )
      : true
    )
    error_message = "When sqs_scale is set, both scale_in_cooldown_seconds and scale_out_cooldown_seconds must be specified and each must be at least 60 seconds."
  }
}