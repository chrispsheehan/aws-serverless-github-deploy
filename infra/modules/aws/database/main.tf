module "database" {
  source = "../_shared/database"

  project_name        = var.project_name
  environment         = var.environment
  database_name       = var.database_name
  subnet_ids          = data.aws_subnets.this.ids
  publicly_accessible = var.publicly_accessible
  database_port       = var.database_port
  engine_version      = var.engine_version

  recovery_class                        = var.recovery_class
  restore_drill                         = var.restore_drill
  rds_min_capacity                      = var.rds_min_capacity
  rds_max_capacity                      = var.rds_max_capacity
  performance_insights_enabled          = var.performance_insights_enabled
  performance_insights_retention_period = var.performance_insights_retention_period
  rds_max_reader_count                  = var.rds_max_reader_count
  database_security_group_id            = var.database_security_group_id
}
