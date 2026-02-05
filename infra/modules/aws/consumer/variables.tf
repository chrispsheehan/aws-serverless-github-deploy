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

variable "deployment_config" {
  description = "Traffic shifting: all_at_once | canary | linear"
  type = object({
    strategy         = string           # all_at_once | canary | linear
    percentage       = optional(number) # 1..99 (req for canary/linear)
    interval_minutes = optional(number) # >=1  (req for canary/linear)
  })
}

variable "sqs_dlq_alarm_threshold" {
  type        = number
  description = "The threshold for the SQS DLQ alarm"
}

variable "sqs_dlq_alarm_evaluation_periods" {
  type        = number
  description = "The number of consecutive periods CloudWatch looks at when deciding the alarm state"
}

variable "sqs_dlq_alarm_datapoints_to_alarm" {
  type        = number
  description = "The number of evaluated periods that must be breaching to trigger ALARM"
}