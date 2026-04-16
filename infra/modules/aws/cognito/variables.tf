### start of static vars set in root.hcl ###
variable "project_name" {
  type        = string
  description = "Project name used in naming resources"
}

variable "environment" {
  type        = string
  description = "Environment reference used in naming resources i.e. 'dev'"
}

variable "aws_region" {
  type        = string
  description = "AWS region"
}

variable "aws_account_id" {
  type        = string
  description = "AWS account id"
}
### end of static vars set in root.hcl ###

variable "callback_urls" {
  type        = list(string)
  description = "OAuth callback URLs allowed for the frontend"

  validation {
    condition     = length(var.callback_urls) > 0
    error_message = "callback_urls must contain at least one URL."
  }
}

variable "logout_urls" {
  type        = list(string)
  description = "OAuth logout URLs allowed for the frontend"

  validation {
    condition     = length(var.logout_urls) > 0
    error_message = "logout_urls must contain at least one URL."
  }
}

variable "domain_name" {
  type        = string
  description = "Base hosted zone domain used to derive the deployed frontend URL"

  validation {
    condition     = length(trimspace(var.domain_name)) > 0
    error_message = "domain_name must be specified."
  }
}

variable "readonly_group_name" {
  type        = string
  description = "Cognito group name for read-only users"
  default     = "readonly"
}

variable "access_token_validity_hours" {
  type        = number
  description = "Access token lifetime in hours"
  default     = 1
}

variable "id_token_validity_hours" {
  type        = number
  description = "ID token lifetime in hours"
  default     = 1
}

variable "refresh_token_validity_days" {
  type        = number
  description = "Refresh token lifetime in days"
  default     = 30
}
