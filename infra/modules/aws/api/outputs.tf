output "invoke_url" {
  value = aws_apigatewayv2_api.http_api.api_endpoint
}

output "cloudwatch_log_group" {
  value = module.lambda_api.cloudwatch_log_group
}

output "lambda_zip_key" {
  value = module.lambda_api.lambda_zip_key
}

output "code_deploy_app_name" {
  value = module.lambda_api.code_deploy_app_name
}

output "code_deploy_group_name" {
  value = module.lambda_api.code_deploy_group_name
}
