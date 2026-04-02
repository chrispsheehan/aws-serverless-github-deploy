variable "vpc_id" {
  type = string
}

variable "service_name" {
  type = string
}

variable "root_path" {
  type = string
}

variable "container_port" {
  type = number
}

variable "default_target_group_arn" {
  type = string
}

variable "default_http_listener_arn" {
  type = string
}

variable "api_vpc_link_id" {
  type = string
}

variable "internal_only" {
  type = string
}
