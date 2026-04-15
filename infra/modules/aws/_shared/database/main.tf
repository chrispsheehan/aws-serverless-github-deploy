resource "random_password" "db_password" {
  length           = local.password_length
  special          = true
  override_special = "!#$%&()*+,-.:;<=>?[]^_{|}~" # Excluding /, @, ", and space
}

resource "random_string" "db_user" {
  length  = local.username_length
  special = false
  upper   = false
}

resource "aws_db_subnet_group" "default" {
  name       = local.subnet_group_name
  subnet_ids = data.aws_subnets.this.ids
}

resource "aws_rds_cluster" "aurora_postgres" {
  cluster_identifier = local.cluster_identifier
  engine             = local.postgres_engine
  engine_version     = data.aws_rds_engine_version.postgres.version
  apply_immediately  = true

  master_username = aws_ssm_parameter.db_username_parameter.value
  master_password = aws_ssm_parameter.db_password_parameter.value

  database_name           = local.serverless_database_name
  backup_retention_period = var.backup_retention_period
  preferred_backup_window = local.postgres_backup_window

  skip_final_snapshot    = true
  vpc_security_group_ids = [data.terraform_remote_state.security.outputs.postgres_sg]
  db_subnet_group_name   = aws_db_subnet_group.default.name
  storage_encrypted      = true

  serverlessv2_scaling_configuration {
    max_capacity = var.rds_max_capacity
    min_capacity = var.rds_min_capacity
  }
}

resource "aws_rds_cluster_instance" "aurora_postgres_instance" {
  identifier           = "${local.cluster_identifier}-writer"
  cluster_identifier   = aws_rds_cluster.aurora_postgres.id
  instance_class       = local.postgres_instance_class
  engine               = local.postgres_engine
  engine_version       = data.aws_rds_engine_version.postgres.version
  publicly_accessible  = var.publicly_accessible
  db_subnet_group_name = aws_db_subnet_group.default.name
  apply_immediately    = true

  performance_insights_enabled          = var.performance_insights_enabled
  performance_insights_retention_period = var.performance_insights_enabled ? var.performance_insights_retention_period : null
}

resource "aws_rds_cluster_instance" "aurora_postgres_reader_instance" {
  count = length(local.subnet_azs)

  identifier           = format("%s-reader-%s", local.cluster_identifier, local.subnet_azs[count.index])
  cluster_identifier   = aws_rds_cluster.aurora_postgres.id
  instance_class       = local.postgres_instance_class
  engine               = local.postgres_engine
  engine_version       = data.aws_rds_engine_version.postgres.version
  publicly_accessible  = var.publicly_accessible
  db_subnet_group_name = aws_db_subnet_group.default.name
  availability_zone    = local.subnet_azs[count.index]
  promotion_tier       = count.index == 0 ? 1 : 2

  performance_insights_enabled          = var.performance_insights_enabled
  performance_insights_retention_period = var.performance_insights_enabled ? var.performance_insights_retention_period : null
}

resource "aws_ssm_parameter" "db_name" {
  name        = local.database_ssm_name
  description = "Database name for ${var.database_name}"
  type        = "SecureString"
  value       = local.serverless_database_name
}

resource "aws_ssm_parameter" "db_password_parameter" {
  name        = local.password_ssm_name
  description = "Password for ${var.database_name}"
  type        = "SecureString"
  value       = random_password.db_password.result
}

resource "aws_ssm_parameter" "db_username_parameter" {
  name        = local.username_ssm_name
  description = "Username for ${var.database_name}"
  type        = "SecureString"
  value       = random_string.db_user.result
}

resource "aws_ssm_parameter" "db_readonly_endpoint_parameter" {
  name        = local.readonly_endpoint_ssm_name
  description = "Read only endpoint for ${var.database_name}"
  type        = "String"
  value       = aws_rds_cluster.aurora_postgres.reader_endpoint
}

resource "aws_ssm_parameter" "db_readwrite_endpoint_parameter" {
  name        = local.readwrite_endpoint_ssm_name
  description = "Read/write endpoint for ${var.database_name}"
  type        = "String"
  value       = aws_rds_cluster.aurora_postgres.endpoint
}
