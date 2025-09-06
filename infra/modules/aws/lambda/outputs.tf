output "name" {
  value = aws_lambda_function.lambda.function_name
}

output "arn" {
  value = aws_lambda_function.lambda.arn
}

output "cloudwatch_log_group" {
  value = aws_cloudwatch_log_group.lambda_cloudwatch_group.name
}

output "code_deploy_app_name" {
  value = aws_codedeploy_app.app.name
}

output "code_deploy_group_name" {
  value = aws_codedeploy_deployment_group.dg.deployment_group_name
}
