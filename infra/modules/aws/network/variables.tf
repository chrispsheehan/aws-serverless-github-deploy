### start of static vars set in root.hcl ###
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
### end of static vars set in root.hcl ###

variable "vpc_name" {
  type = string
}

variable "container_port" {
  type    = number
  default = 80
}

variable "local_tunnel" {
  type    = bool
  default = false
}

variable "xray_enabled" {
  type    = bool
  default = false
}
