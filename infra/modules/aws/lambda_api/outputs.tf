output "invoke_url" {
  value = var.network_api_invoke_url
}

output "api_id" {
  value = var.network_api_id
}

output "vpc_link_id" {
  value = var.network_vpc_link_id
}

output "cloudwatch_log_group" {
  value = module.lambda_api.cloudwatch_log_group
}

output "lambda_arn" {
  value = module.lambda_api.arn
}

output "lambda_function_name" {
  value = module.lambda_api.function_name
}

output "lambda_alias_name" {
  value = module.lambda_api.alias_name
}
