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

variable "sqs_queue_name" {
  type        = string
  description = "The name of the SQS queue"
}

variable "deployment_config" {
  description = "Traffic shifting: all_at_once | canary | linear"
  type = object({
    strategy         = string           # all_at_once | canary | linear
    percentage       = optional(number) # 1..99 (req for canary/linear)
    interval_minutes = optional(number) # >=1  (req for canary/linear)
  })
}

variable "provisioned_config" {
  description = "Either fixed provisioned concurrency (fixed) or autoscaled (auto_scale); omit/zero = none"
  type = object({
    fixed                = optional(number) # 0/omit = off, >0 = fixed PC
    reserved_concurrency = optional(number) # 0/omit = no concurrency limit, >0 = limited concurrency

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