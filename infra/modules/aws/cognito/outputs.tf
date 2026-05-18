output "auth_user_pool_id" {
  value = aws_cognito_user_pool.this.id
}

output "auth_user_pool_arn" {
  value = aws_cognito_user_pool.this.arn
}

output "auth_user_pool_client_id" {
  value = aws_cognito_user_pool_client.frontend.id
}

output "auth_issuer_url" {
  value = local.issuer_url
}

output "auth_hosted_ui_url" {
  value = local.hosted_ui_url
}

output "auth_hosted_ui_domain" {
  value = aws_cognito_user_pool_domain.this.domain
}

output "auth_readonly_group_name" {
  value = aws_cognito_user_group.readonly.name
}
