variable "state_bucket" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "code_bucket" {
  type = string
}

variable "otel_sample_rate" {
  type    = number
  default = 1.0
}

variable "vpc_name" {
  type = string
}
