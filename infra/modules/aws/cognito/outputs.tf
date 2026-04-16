output "user_pool_id" {
  value = aws_cognito_user_pool.this.id
}

output "user_pool_arn" {
  value = aws_cognito_user_pool.this.arn
}

output "user_pool_client_id" {
  value = aws_cognito_user_pool_client.frontend.id
}

output "issuer_url" {
  value = local.issuer_url
}

output "hosted_ui_url" {
  value = local.hosted_ui_url
}

output "hosted_ui_domain" {
  value = aws_cognito_user_pool_domain.this.domain
}

output "readonly_group_name" {
  value = aws_cognito_user_group.readonly.name
}
