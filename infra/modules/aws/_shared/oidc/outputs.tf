output "oidc_provider_arn" {
  description = "OIDC provider ARN."
  value       = aws_iam_openid_connect_provider.github_actions.arn
}

output "oidc_role" {
  description = "GitHub Actions OIDC role ARN."
  value       = aws_iam_role.github_actions.arn
}
