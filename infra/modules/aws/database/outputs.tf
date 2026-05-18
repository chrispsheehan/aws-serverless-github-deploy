output "database_credentials_secret_arn" {
  value = module.database.credentials_secret_arn
}

output "database_readonly_endpoint_ssm_name" {
  value = module.database.readonly_endpoint_ssm_name
}

output "database_readwrite_endpoint_ssm_name" {
  value = module.database.readwrite_endpoint_ssm_name
}

output "database_cluster_identifier" {
  value = module.database.cluster_identifier
}

output "database_security_group_id" {
  value = module.database.security_group_id
}

output "database_name" {
  value = module.database.database_name
}

output "database_port" {
  value = module.database.database_port
}

output "database_readonly_endpoint" {
  value = module.database.readonly_endpoint
}

output "database_readwrite_endpoint" {
  value = module.database.readwrite_endpoint
}
