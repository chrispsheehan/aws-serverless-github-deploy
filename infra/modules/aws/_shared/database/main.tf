resource "random_string" "db_user_suffix" {
  length  = local.username_suffix_length
  special = false
  upper   = false
  numeric = true
}

resource "aws_db_subnet_group" "default" {
  name       = local.subnet_group_name
  subnet_ids = var.subnet_ids
}

resource "aws_rds_cluster" "aurora_postgres" {
  cluster_identifier = local.cluster_identifier
  engine             = local.postgres_engine
  engine_version     = data.aws_rds_engine_version.postgres.version
  apply_immediately  = true

  master_username             = local.master_username
  manage_master_user_password = true

  database_name           = local.serverless_database_name
  backup_retention_period = local.recovery_profile.backup_retention_period
  preferred_backup_window = local.postgres_backup_window
  deletion_protection     = local.recovery_profile.deletion_protection

  skip_final_snapshot       = local.recovery_profile.skip_final_snapshot
  final_snapshot_identifier = local.final_snapshot_identifier
  vpc_security_group_ids    = [var.database_security_group_id]
  db_subnet_group_name      = aws_db_subnet_group.default.name
  storage_encrypted         = true

  tags = {
    RecoveryClass       = var.recovery_class
    RestoreDrillCadence = local.recovery_profile.restore_drill_cadence
    TargetRPOMinutes    = tostring(local.recovery_profile.target_rpo_minutes)
    TargetRTOMinutes    = tostring(local.recovery_profile.target_rto_minutes)
  }

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
  count = local.reader_count

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

resource "aws_iam_role" "restore_drill_sfn" {
  count = local.restore_drill_state_machine_enabled ? 1 : 0

  name               = "${local.cluster_identifier}-restore-drill-sfn"
  assume_role_policy = data.aws_iam_policy_document.restore_drill_sfn_assume.json
}

resource "aws_iam_role_policy" "restore_drill_sfn" {
  count = local.restore_drill_state_machine_enabled ? 1 : 0

  name   = "${local.cluster_identifier}-restore-drill-sfn"
  role   = aws_iam_role.restore_drill_sfn[count.index].id
  policy = data.aws_iam_policy_document.restore_drill_sfn.json
}

resource "aws_sfn_state_machine" "restore_drill" {
  count = local.restore_drill_state_machine_enabled ? 1 : 0

  name     = "${local.cluster_identifier}-restore-drill"
  role_arn = aws_iam_role.restore_drill_sfn[count.index].arn

  definition = local.restore_drill_state_machine_definition
}

resource "aws_iam_role" "restore_drill_scheduler" {
  count = local.restore_drill_schedule_enabled ? 1 : 0

  name               = "${local.cluster_identifier}-restore-drill-scheduler"
  assume_role_policy = data.aws_iam_policy_document.restore_drill_scheduler_assume.json
}

resource "aws_iam_role_policy" "restore_drill_scheduler" {
  count = local.restore_drill_schedule_enabled ? 1 : 0

  name   = "${local.cluster_identifier}-restore-drill-scheduler"
  role   = aws_iam_role.restore_drill_scheduler[count.index].id
  policy = data.aws_iam_policy_document.restore_drill_scheduler.json
}

resource "aws_scheduler_schedule" "restore_drill" {
  count = local.restore_drill_schedule_enabled ? 1 : 0

  name                         = "${local.cluster_identifier}-restore-drill"
  group_name                   = "default"
  schedule_expression          = local.restore_drill.schedule_expression
  schedule_expression_timezone = "UTC"
  state                        = "ENABLED"

  flexible_time_window {
    mode = "OFF"
  }

  target {
    arn      = aws_sfn_state_machine.restore_drill[count.index].arn
    role_arn = aws_iam_role.restore_drill_scheduler[count.index].arn

    input = jsonencode({
      trigger_mode = "scheduled"
    })
  }
}
