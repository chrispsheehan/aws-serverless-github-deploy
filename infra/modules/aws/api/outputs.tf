output "invoke_url" {
  value = aws_apigatewayv2_api.http_api.api_endpoint
}

output "api_id" {
  value = aws_apigatewayv2_api.http_api.id
}

output "vpc_link_id" {
  value = aws_apigatewayv2_vpc_link.http_api.id
}

output "vpc_link_security_group_id" {
  value = aws_security_group.api_vpc_link.id
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
