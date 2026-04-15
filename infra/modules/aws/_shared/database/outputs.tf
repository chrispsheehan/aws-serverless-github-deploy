output "username_ssm_name" {
  value = local.username_ssm_name
}

output "password_ssm_name" {
  value = local.password_ssm_name
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
