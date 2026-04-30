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

variable "subnet_ids" {
  type        = list(string)
  description = "Subnet ids to use for the database subnet group and reader availability-zone selection"

  validation {
    condition     = length(var.subnet_ids) > 0
    error_message = "subnet_ids must contain at least one subnet id."
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

variable "recovery_class" {
  type        = string
  description = "Recovery posture preset for the Aurora cluster."
  default     = "standard"

  validation {
    condition     = contains(["dev", "standard", "critical"], var.recovery_class)
    error_message = "recovery_class must be one of: dev, standard, critical."
  }
}

variable "restore_drill" {
  description = "Optional restore-drill automation for this Aurora cluster."
  type = object({
    enabled      = optional(bool, false)
    mode         = optional(string, "manual")
    use_pitr     = optional(bool, true)
    retain_hours = optional(number, 4)
  })
  default = {}

  validation {
    condition = contains(
      ["manual", "scheduled", "manual_and_scheduled"],
      coalesce(var.restore_drill.mode, "manual"),
    )
    error_message = "restore_drill.mode must be manual, scheduled, or manual_and_scheduled."
  }

  validation {
    condition     = coalesce(var.restore_drill.retain_hours, 4) >= 0
    error_message = "restore_drill.retain_hours must be zero or greater."
  }
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
