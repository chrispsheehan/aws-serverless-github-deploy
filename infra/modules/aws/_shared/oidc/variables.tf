variable "deploy_role_name" {
  description = "Name of the IAM role assumed by GitHub Actions."
  type        = string
}

variable "environment" {
  description = "Environment name for role description context."
  type        = string
}

variable "github_repo" {
  description = "GitHub owner/repository slug allowed to assume the role."
  type        = string
}

variable "allowed_role_actions" {
  description = "IAM actions allowed for the GitHub Actions role."
  type        = list(string)
}

variable "github_thumbprint" {
  description = "GitHub OIDC TLS certificate thumbprint."
  type        = string
  default     = "6938fd4d98bab03faadb97b34396831e3780aea1"
}

variable "max_session_duration" {
  description = "Maximum session duration in seconds."
  type        = number
  default     = 3600
}
