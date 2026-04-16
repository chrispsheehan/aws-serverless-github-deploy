locals {
  name                 = "${var.environment}-${var.project_name}"
  bucket_name          = "${data.aws_caller_identity.current.account_id}-${local.name}"
  api_domain           = replace(var.api_invoke_url, "https://", "")
  frontend_domain_name = "${var.project_name}.${var.environment}.${var.domain_name}"
  hosted_zone_name     = var.frontend_hosted_zone_name != "" ? trimsuffix(var.frontend_hosted_zone_name, ".") : var.domain_name
  auth_config = jsonencode({
    enabled          = true
    region           = var.aws_region
    userPoolId       = data.terraform_remote_state.cognito.outputs.user_pool_id
    userPoolClientId = data.terraform_remote_state.cognito.outputs.user_pool_client_id
    hostedUiUrl      = data.terraform_remote_state.cognito.outputs.hosted_ui_url
    readonlyGroup    = data.terraform_remote_state.cognito.outputs.readonly_group_name
    scopes           = ["openid", "email", "profile"]
  })

  s3_origin_id  = "s3"
  api_origin_id = "api"

  root_file                  = "index.html"
  auth_config_file           = "auth-config.json"
  caching_optimized_id       = "Managed-CachingOptimized"
  origin_request_policy_id   = "Managed-CORS-S3Origin"
  response_headers_policy_id = "Managed-CORS-With-Preflight"
  caching_disabled_id        = "Managed-CachingDisabled"
}
