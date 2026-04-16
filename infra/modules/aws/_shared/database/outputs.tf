output "credentials_secret_name" {
  value = data.aws_secretsmanager_secret.db_credentials.name
}

output "credentials_secret_arn" {
  value = data.aws_secretsmanager_secret.db_credentials.arn
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
