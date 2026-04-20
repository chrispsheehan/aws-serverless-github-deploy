locals {
  name                        = "${var.environment}-${var.project_name}"
  bucket_name                 = "${data.aws_caller_identity.current.account_id}-${local.name}"
  api_domain                  = replace(var.api_invoke_url, "https://", "")
  frontend_domain_name        = "${var.project_name}.${var.environment}.${var.domain_name}"
  hosted_zone_name            = var.frontend_hosted_zone_name != "" ? trimsuffix(var.frontend_hosted_zone_name, ".") : var.domain_name
  observability_dashboard_url = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${var.environment}-${var.project_name}-observability"
  auth_config = jsonencode({
    enabled                   = true
    region                    = var.aws_region
    userPoolId                = var.auth_user_pool_id
    userPoolClientId          = var.auth_user_pool_client_id
    hostedUiUrl               = var.auth_hosted_ui_url
    readonlyGroup             = var.auth_readonly_group_name
    observabilityDashboardUrl = local.observability_dashboard_url
    scopes                    = ["openid", "email", "profile"]
  })

  s3_origin_id  = "s3"
  api_origin_id = "api"

  root_file                    = "index.html"
  auth_config_file             = "auth-config.json"
  caching_optimized_id         = "Managed-CachingOptimized"
  origin_request_policy_id     = "Managed-CORS-S3Origin"
  api_origin_request_policy_id = "Managed-AllViewerExceptHostHeader"
  response_headers_policy_id   = "Managed-CORS-With-Preflight"
  caching_disabled_id          = "Managed-CachingDisabled"
}
