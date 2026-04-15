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

variable "database_name" {
  type        = string
  description = "Logical database name used for naming resources and the initial database"
}

variable "vpc_name" {
  type        = string
  description = "VPC name tag used to look up the database VPC and subnets"

  validation {
    condition     = length(trimspace(var.vpc_name)) > 0
    error_message = "vpc_name must be specified."
  }
}

variable "publicly_accessible" {
  type        = bool
  description = "Whether cluster instances should be publicly accessible"
  default     = false
}

variable "database_port" {
  type        = number
  description = "Database listener port"
  default     = 5432
}

variable "engine_version" {
  type        = string
  description = "Aurora PostgreSQL engine version selector to use. Partial versions are allowed and resolved to the latest matching version."
  default     = "16"
}

variable "backup_retention_period" {
  type        = number
  description = "Days to retain automated backups"
  default     = 7
}

variable "rds_min_capacity" {
  type        = number
  description = "Minimum Aurora Serverless v2 capacity in ACUs"
  default     = 0.5
}

variable "rds_max_capacity" {
  type        = number
  description = "Maximum Aurora Serverless v2 capacity in ACUs"
  default     = 1.0
}

variable "performance_insights_enabled" {
  type        = bool
  description = "Whether to enable Performance Insights on cluster instances"
  default     = false
}

variable "performance_insights_retention_period" {
  type        = number
  description = "Performance Insights retention in days"
  default     = 7

  validation {
    condition     = contains([7, 731], var.performance_insights_retention_period)
    error_message = "Performance Insights retention must be 7 or 731 days."
  }
}

variable "rds_max_reader_count" {
  type        = number
  description = "Maximum number of Aurora reader instances to create"
  default     = 0
}

variable "database_security_group_id" {
  type        = string
  description = "Security group id to attach to the Aurora cluster"

  validation {
    condition     = length(trimspace(var.database_security_group_id)) > 0
    error_message = "database_security_group_id must be specified."
  }
}
