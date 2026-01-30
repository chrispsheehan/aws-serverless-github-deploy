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

variable "api_5xx_alarm_threshold" {
  type        = number
  description = "The threshold for the API 5xx error rate alarm"
}

variable "api_5xx_alarm_evaluation_periods" {
  type        = number
  description = "The number of consecutive periods CloudWatch looks at when deciding the alarm state"
}

variable "api_5xx_alarm_datapoints_to_alarm" {
  type        = number
  description = "The number of evaluated periods that must be breaching to trigger ALARM"
}