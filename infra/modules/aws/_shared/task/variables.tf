variable "project_name" {
  type = string
}

variable "ecr_repository_name" {
  type = string
}

variable "service_name" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "container_port" {
  type = number
}

variable "cpu" {
  type    = number
  default = 256
}

variable "memory" {
  type    = number
  default = 512
}

variable "image_uri" {
  type = string
}

variable "aws_otel_collector_image_uri" {
  type = string
}

variable "otel_sampling_percentage" {
  description = "Percentage of requests to send to x-ray"
  type        = string
  default     = 10.0
}

variable "debug_image_uri" {
  type = string
}

variable "local_tunnel" {
  type = bool
}

variable "xray_enabled" {
  type = bool
}

variable "additional_env_vars" {
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "command" {
  type     = list(string)
  nullable = true
}

variable "root_path" {
  type = string
}

variable "additional_runtime_policy_arns" {
  description = "List of IAM runtime policy ARNs to attach to the role"
  type        = list(string)
  default     = []
}
