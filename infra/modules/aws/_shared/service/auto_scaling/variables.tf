variable "cluster_name" {
  type = string
}

variable "service_name" {
  type = string
}

variable "initial_task_count" {
  type = number
}

variable "load_balancer_arn_suffix" {
  type = string
}

variable "target_group_arn_suffix" {
  type = string
}

variable "scaling_strategy" {
  type = object({
    max_scaled_task_count = optional(number)
    cpu = optional(object({
      scale_out_threshold  = number
      scale_in_threshold   = number
      scale_out_adjustment = number
      scale_in_adjustment  = number
      cooldown_out         = number
      cooldown_in          = number
    }))
    sqs = optional(object({
      scale_out_threshold  = number
      scale_in_threshold   = number
      scale_out_adjustment = number
      scale_in_adjustment  = number
      cooldown_out         = number
      cooldown_in          = number
      queue_name           = string
    }))
    alb = optional(object({
      target_requests_per_task = number
      cooldown_in              = number
      cooldown_out             = number
    }))
  })

  # {} = "off" by convention
  default = {}

  validation {
    condition = (
      // number of non-null strategies must be <= 1
      (
        (try(var.scaling_strategy.cpu != null, false) ? 1 : 0) +
        (try(var.scaling_strategy.alb != null, false) ? 1 : 0) +
        (try(var.scaling_strategy.sqs != null, false) ? 1 : 0)
      ) <= 1
    )

    error_message = "Only one of scaling_strategy.cpu, scaling_strategy.alb, or scaling_strategy.sqs may be set at a time to avoid conflicting autoscalers."
  }
}