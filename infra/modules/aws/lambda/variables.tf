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

variable "deploy_strategy" {
  description = "Traffic shifting: all_at_once | canary | linear"
  type        = string
  default     = "canary"
  validation {
    condition     = contains(["all_at_once", "canary", "linear"], var.deploy_strategy)
    error_message = "deploy_strategy must be one of: all_at_once, canary, linear."
  }
}

variable "deploy_percentage" {
  description = "Percent for first step (canary) or each step (linear). 1..99"
  type        = number
  default     = 50
  validation {
    condition     = var.deploy_percentage >= 1 && var.deploy_percentage <= 99
    error_message = "deploy_percentage must be between 1 and 99."
  }
}

variable "deploy_interval_minutes" {
  description = "Minutes between shifts (>=1)."
  type        = number
  default     = 1
  validation {
    condition     = var.deploy_interval_minutes >= 1
    error_message = "deploy_interval_minutes must be >= 1."
  }
}

variable "provisioned_concurrency" {
  description = "Fixed PC via fixed_count, or autoscaled via util_min/max; leave all zero for none"
  type = object({
    fixed_count           = optional(number)  # 0 = off, >0 = fixed PC
    util_min              = optional(number)  # autoscaled: minimum PC
    util_max              = optional(number)  # autoscaled: maximum PC
    util_target           = optional(number)  # autoscaled target 0<..<=1 (default 0.7)
    util_scale_in_cd      = optional(number)  # seconds (default 60)
    util_scale_out_cd     = optional(number)  # seconds (default 30)
  })
  default = {
    fixed_count = 0
  }

  # Don’t allow fixed and autoscaled simultaneously
  validation {
    condition = !(
      try(var.provisioned_concurrency.fixed_count, 0) > 0 &&
      (try(var.provisioned_concurrency.util_min, 0) > 0 || try(var.provisioned_concurrency.util_max, 0) > 0)
    )
    error_message = "Use either fixed_count>0 (fixed) OR util_min/max>0 (autoscaled), not both."
  }
}
