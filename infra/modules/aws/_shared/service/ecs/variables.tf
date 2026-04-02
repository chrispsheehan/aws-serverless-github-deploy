variable "cluster_id" {
  type = string
}

variable "service_name" {
  type = string
}

variable "desired_task_count" {
  type = number
}

variable "load_balancers" {
  type = list(object({
    target_group_arn = string
    container_name   = string
    container_port   = number
  }))
  default = []
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "security_group_ids" {
  type = list(string)
}

variable "container_port" {
  type = number
}

variable "task_definition_arn" {
  type = string
}

variable "local_tunnel" {
  type    = bool
  default = false
}

variable "xray_enabled" {
  type = bool
}

variable "wait_for_steady_state" {
  type    = bool
  default = true
}