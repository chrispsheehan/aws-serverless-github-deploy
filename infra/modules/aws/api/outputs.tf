output "invoke_url" {
  value = aws_apigatewayv2_api.http_api.api_endpoint
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
