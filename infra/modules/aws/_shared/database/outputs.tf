output "username_ssm_name" {
  value = local.username_ssm_name
}

output "password_ssm_name" {
  value = local.password_ssm_name
}

output "username_ssm_arn" {
  value = aws_ssm_parameter.db_username_parameter.arn
}

output "password_ssm_arn" {
  value = aws_ssm_parameter.db_password_parameter.arn
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
  value = data.terraform_remote_state.security.outputs.postgres_sg
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
