### start of static vars set in root.hcl ###
variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}
### end of static vars set in root.hcl ###

variable "vpc_name" {
  type = string
}

variable "container_port" {
  type = number
}

variable "additional_listener_port" {
  type    = number
  default = 8080
}
