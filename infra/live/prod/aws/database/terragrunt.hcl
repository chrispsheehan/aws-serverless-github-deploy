include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  database_security = read_terragrunt_config(find_in_parent_folders("dependencies/database_security.hcl"))
}

terraform {
  source = "../../../../modules//aws//database"
}

inputs = merge(
  local.database_security.inputs,
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
