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
