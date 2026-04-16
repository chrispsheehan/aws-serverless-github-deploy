output "default_target_group_arn" {
  value = aws_lb_target_group.default.arn
}

output "load_balancer_arn" {
  value = aws_lb.this.arn
}

output "default_http_listener_arn" {
  value = aws_lb_listener.http.arn
}

output "load_balancer_arn_suffix" {
  value = aws_lb.this.arn_suffix
}

output "target_group_arn_suffix" {
  value = aws_lb_target_group.default.arn_suffix
}

output "internal_invoke_url" {
  value = "http://${aws_lb.this.dns_name}"
}

output "api_id" {
  value = aws_apigatewayv2_api.http_api.id
}

output "api_invoke_url" {
  value = aws_apigatewayv2_api.http_api.api_endpoint
}

output "api_execution_arn" {
  value = aws_apigatewayv2_api.http_api.execution_arn
}

output "api_stage_name" {
  value = aws_apigatewayv2_stage.default.name
}

output "vpc_link_id" {
  value = aws_apigatewayv2_vpc_link.http_api.id
}

output "http_api_authorizer_id" {
  value = aws_apigatewayv2_authorizer.cognito_jwt.id
}
