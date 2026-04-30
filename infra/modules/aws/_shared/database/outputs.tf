output "credentials_secret_arn" {
  value = try(one(aws_rds_cluster.aurora_postgres.master_user_secret).secret_arn, null)
}

output "readonly_endpoint_ssm_name" {
  value = local.readonly_endpoint_ssm_name
}

output "readwrite_endpoint_ssm_name" {
  value = local.readwrite_endpoint_ssm_name
}

output "cluster_identifier" {
  value = aws_rds_cluster.aurora_postgres.cluster_identifier
}

output "security_group_id" {
  value = var.database_security_group_id
}

output "database_name" {
  value = local.serverless_database_name
}

output "database_port" {
  value = var.database_port
}

output "readonly_endpoint" {
  value = aws_rds_cluster.aurora_postgres.reader_endpoint
}

output "readwrite_endpoint" {
  value = aws_rds_cluster.aurora_postgres.endpoint
}

output "recovery_class" {
  value = var.recovery_class
}

output "restore_drill_cadence" {
  value = local.recovery_profile.restore_drill_cadence
}

output "target_rpo_minutes" {
  value = local.recovery_profile.target_rpo_minutes
}

output "target_rto_minutes" {
  value = local.recovery_profile.target_rto_minutes
}

output "restore_drill_enabled" {
  value = local.restore_drill.enabled
}

output "restore_drill_mode" {
  value = local.restore_drill.mode
}

output "restore_drill_schedule_expression" {
  value = try(local.restore_drill.schedule_expression, null)
}

output "restore_drill_state_machine_arn" {
  value = try(aws_sfn_state_machine.restore_drill[0].arn, null)
}

output "restore_drill_state_machine_name" {
  value = try(aws_sfn_state_machine.restore_drill[0].name, null)
}
