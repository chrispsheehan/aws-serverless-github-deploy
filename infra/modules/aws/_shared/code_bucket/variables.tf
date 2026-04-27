### start of static vars set in root.hcl ###
variable "code_bucket" {
  description = "S3 bucket to host build artifacts"
  type        = string
}
### end of static vars set in root.hcl ###

variable "lambda_artifact_dir" {
  description = "Top-level S3 prefix used for Lambda zip artifacts"
  type        = string
  default     = "lambdas"
}

variable "frontend_artifact_dir" {
  description = "Top-level S3 prefix used for frontend build artifacts"
  type        = string
  default     = "frontend"
}

variable "appspec_artifact_dir" {
  description = "Top-level S3 prefix used for AppSpec deployment artifacts"
  type        = string
  default     = "appspec"
}

variable "infra_plan_dir" {
  description = "Top-level S3 prefix used for saved Terragrunt plan artifacts"
  type        = string
  default     = "terragrunt_plan"
}

variable "code_artifact_expiration_days" {
  description = "Number of days before deployable code artifacts under lambdas/, frontend/, and appspec/ are deleted (set to 0 to disable)"
  type        = number
  default     = 0
}

variable "infra_plan_artifact_expiration_days" {
  description = "Number of days before saved Terragrunt plan artifacts under terragrunt_plan/ are deleted (set to 0 to disable)"
  type        = number
  default     = 0
}
