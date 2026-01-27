output "cloudwatch_log_group" {
  value = module.lambda_consumer.cloudwatch_log_group
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
