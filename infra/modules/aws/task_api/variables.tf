### start of static vars set in root.hcl ###
variable "state_bucket" {
  type = string
}

variable "environment" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "project_name" {
  type = string
}

variable "ecr_repository_name" {
  type = string
}
### end of static vars set in root.hcl ###

variable "container_port" {
  type    = number
  default = 80
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
  type    = bool
  default = false
}

variable "xray_enabled" {
  type    = bool
  default = false
}
