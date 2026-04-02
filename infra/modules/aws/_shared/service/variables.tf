variable "state_bucket" {
  type = string
}

variable "environment" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "vpc_name" {
  type = string
}

variable "service_name" {
  type = string
}

variable "container_port" {
  type = number
}

variable "task_definition_arn" {
  type = string
}

variable "root_path" {
  description = "The path to serve the service from. / is for default /example_service is for subpath"
  type        = string
  default     = ""
}

variable "connection_type" {
  description = "Type of connectivity/integration to use for the service (choices: internal, internal_dns, vpc_link)."
  type        = string
  validation {
    condition     = can(regex("^(internal|internal_dns|vpc_link)$", var.connection_type))
    error_message = "connection_type must be one of: internal, internal_dns, vpc_link."
  }
}

variable "local_tunnel" {
  type    = bool
  default = false
}

variable "xray_enabled" {
  type    = bool
  default = false
}

variable "wait_for_steady_state" {
  type    = bool
  default = false
}

variable "additional_security_group_ids" {
  description = "List of security groups to attach to ECS service"
  type        = list(string)
  default     = []
}

variable "desired_task_count" {
  type = number
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
}
