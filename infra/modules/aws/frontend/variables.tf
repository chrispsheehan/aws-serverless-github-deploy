### start of static vars set in root.hcl ###
variable "project_name" {
  type        = string
  description = "Project name used in naming resources"
}

variable "environment" {
  type        = string
  description = "Environment reference used in naming resources i.e. 'dev'"
}
### end of static vars set in root.hcl ###

variable "api_invoke_url" {
  type        = string
  description = "The API Gateway v2 invoke URL (https://...)"
}
