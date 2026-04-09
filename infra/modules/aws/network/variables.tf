variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "state_bucket" {
  type = string
}

variable "vpc_name" {
  type = string
}

variable "container_port" {
  type = number
}

variable "local_tunnel" {
  type    = bool
  default = false
}

variable "xray_enabled" {
  type    = bool
  default = false
}
