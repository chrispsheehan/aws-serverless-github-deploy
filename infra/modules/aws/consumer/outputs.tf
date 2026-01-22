output "cloudwatch_log_group" {
  value = module.lambda_consumer.cloudwatch_log_group
}

output "lambda_zip_key" {
  value = module.lambda_consumer.lambda_zip_key
}

output "lambda_appspec_key" {
  value = module.lambda_consumer.lambda_appspec_key
}

output "code_deploy_app_name" {
  value = module.lambda_consumer.code_deploy_app_name
}

output "code_deploy_group_name" {
  value = module.lambda_consumer.code_deploy_group_name
}

output "lambda_arn" {
  value = module.lambda_consumer.arn
}

output "lambda_function_name" {
  value = module.lambda_consumer.function_name
}

output "lambda_alias_name" {
  value = module.lambda_consumer.alias_name
}
