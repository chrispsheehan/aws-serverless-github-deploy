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

variable "service_name" {
  type    = string
  default = "ecs-service-api"
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
  default     = "ecs"
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

variable "assign_public_ip" {
  type        = bool
  description = "Whether to place ECS tasks in public subnets and assign public IPs for direct outbound internet egress. The public API path still reaches tasks through API Gateway, VPC Link, the internal ALB, and each task's private IP."
  default     = true
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

variable "ecs_security_group_id" {
  type = string
}

variable "task_definition_arn" {
  type    = string
  default = "arn:aws:ecs:eu-west-2:111111111111:task-definition/mock-task-api:1"
}

variable "cluster_id" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "network_default_target_group_arn" {
  type = string
}

variable "network_load_balancer_arn" {
  type = string
}

variable "network_default_http_listener_arn" {
  type = string
}

variable "network_load_balancer_arn_suffix" {
  type = string
}

variable "network_target_group_arn_suffix" {
  type = string
}

variable "network_api_id" {
  type = string
}

variable "network_vpc_link_id" {
  type = string
}

variable "network_internal_invoke_url" {
  type = string
}

variable "network_api_invoke_url" {
  type = string
}

variable "network_http_api_authorizer_id" {
  type = string
}
