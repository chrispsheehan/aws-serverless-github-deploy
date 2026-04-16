include {
  path = find_in_parent_folders("root.hcl")
}

inputs = {
  database_name                = "app"
  backup_retention_period      = 1
  rds_min_capacity             = 0.5
  rds_max_capacity             = 1.0
  rds_max_reader_count         = 0
  performance_insights_enabled = false
}

terraform {
  source = "../../../../modules//aws//_shared//database"
}
