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