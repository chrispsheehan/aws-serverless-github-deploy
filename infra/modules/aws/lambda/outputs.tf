output "name" {
  value = aws_lambda_function.lambda.function_name
}

output "arn" {
  value = aws_lambda_function.lambda.arn
}

output "function_name" {
  value = aws_lambda_function.lambda.function_name
}

output "alias_name" {
  value = aws_lambda_alias.live.name
}

output "cloudwatch_log_group" {
  value = aws_cloudwatch_log_group.lambda_cloudwatch_group.name
}

output "lambda_zip_key" {
  value = local.lambda_code_zip_key
}

output "code_deploy_app_name" {
  value = aws_codedeploy_app.app.name
}

output "code_deploy_group_name" {
  value = aws_codedeploy_deployment_group.dg.deployment_group_name
}
