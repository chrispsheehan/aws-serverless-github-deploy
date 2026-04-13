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
### end of static vars set in root.hcl ###

variable "service_name" {
  type    = string
  default = "ecs-blue-green-api"
}

variable "vpc_name" {
  type = string
}

variable "container_port" {
  type    = number
  default = 80
}

variable "root_path" {
  description = "The path to serve the service from. / is for default /example_service is for subpath"
  default     = "blue-green-api"
  type        = string
}

variable "connection_type" {
  description = "Type of connectivity/integration to use for the service (choices: internal, internal_dns, vpc_link)."
  type        = string
  default     = "vpc_link"
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

variable "bootstrap" {
  type    = bool
  default = false
}

variable "bootstrap_image_uri" {
  type    = string
  default = ""

  validation {
    condition     = !var.bootstrap || var.bootstrap_image_uri != ""
    error_message = "bootstrap_image_uri must be set when bootstrap is true."
  }
}
