locals {
  password_length             = 30
  username_prefix             = "app"
  username_suffix_length      = 8
  master_username             = "${local.username_prefix}${random_string.db_user_suffix.result}"
  ssm_name_prefix             = "/${var.environment}/${var.project_name}/${var.database_name}"
  database_ssm_name           = "${local.ssm_name_prefix}/db-name"
  username_ssm_name           = "${local.ssm_name_prefix}/username"
  password_ssm_name           = "${local.ssm_name_prefix}/password"
  readonly_endpoint_ssm_name  = "${local.ssm_name_prefix}/readonly-endpoint"
  readwrite_endpoint_ssm_name = "${local.ssm_name_prefix}/readwrite-endpoint"

  cluster_identifier       = "${var.project_name}-${var.environment}-${var.database_name}-aurora"
  subnet_group_name        = "${var.project_name}-${var.environment}-${var.database_name}-rds-subnet-group"
  security_group_name      = "${var.project_name}-${var.environment}-${var.database_name}-postgres-sg"
  serverless_database_name = replace(var.database_name, "-", "_")

  postgres_engine         = "aurora-postgresql"
  postgres_instance_class = "db.serverless"
  postgres_backup_window  = "07:00-09:00"

  subnet_ids_ordered = tolist(data.aws_subnets.this.ids)
  subnet_azs_all     = [for id in local.subnet_ids_ordered : data.aws_subnet.selected[id].availability_zone]
  subnet_azs         = slice(distinct(local.subnet_azs_all), 0, var.rds_max_reader_count)
}
