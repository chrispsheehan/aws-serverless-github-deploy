output "credentials_secret_arn" {
  value = module.database.credentials_secret_arn
}

output "readonly_endpoint_ssm_name" {
  value = module.database.readonly_endpoint_ssm_name
}

output "readwrite_endpoint_ssm_name" {
  value = module.database.readwrite_endpoint_ssm_name
}

output "cluster_identifier" {
  value = module.database.cluster_identifier
}

output "security_group_id" {
  value = module.database.security_group_id
}

output "database_name" {
  value = module.database.database_name
}

output "database_port" {
  value = module.database.database_port
}

output "readonly_endpoint" {
  value = module.database.readonly_endpoint
}

output "readwrite_endpoint" {
  value = module.database.readwrite_endpoint
}

output "manual_snapshot_identifier_prefix" {
  value = module.database.manual_snapshot_identifier_prefix
}
