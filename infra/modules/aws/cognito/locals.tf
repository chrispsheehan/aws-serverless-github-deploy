locals {
  cognito_domain_seed  = replace(lower("${var.project_name}-${var.environment}-${var.aws_account_id}"), "aws", "app")
  domain_prefix        = substr(replace(local.cognito_domain_seed, "_", "-"), 0, 63)
  issuer_url           = "https://cognito-idp.${var.aws_region}.amazonaws.com/${aws_cognito_user_pool.this.id}"
  hosted_ui_url        = "https://${aws_cognito_user_pool_domain.this.domain}.auth.${var.aws_region}.amazoncognito.com"
  frontend_domain_name = "${var.project_name}.${var.environment}.${var.domain_name}"
  frontend_url         = "https://${local.frontend_domain_name}"
  callback_urls        = distinct(compact(concat(var.callback_urls, [local.frontend_url])))
  logout_urls          = distinct(compact(concat(var.logout_urls, [local.frontend_url])))
}
