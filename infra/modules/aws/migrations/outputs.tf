output "lambda_function_name" {
  value = module.migrations.function_name
}

output "lambda_alias_name" {
  value = module.migrations.alias_name
}

output "cloudwatch_log_group" {
  value = module.migrations.cloudwatch_log_group
}
