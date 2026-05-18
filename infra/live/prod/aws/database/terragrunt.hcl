include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "security" {
  path = find_in_parent_folders("dependencies/security.hcl")
}

terraform {
  source = "../../../../modules//aws//database"
}

inputs = merge(
  {
    database_security_group_id = dependency.security.outputs.postgres_sg
  },
  {
    database_name                         = "app"
    backup_retention_period               = 7
    rds_min_capacity                      = 0.5
    rds_max_capacity                      = 2.0
    rds_max_reader_count                  = 1
    performance_insights_enabled          = true
    performance_insights_retention_period = 7
  },
)
