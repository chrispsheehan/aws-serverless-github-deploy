locals {
  deploy_branches          = ["*"]
  image_expiration_days    = 30
  force_delete             = true
  local_tunnel             = true
  xray_enabled             = true
  otel_sampling_percentage = 100
  cognito_callback_urls    = ["http://localhost:5173"]
  cognito_logout_urls      = ["http://localhost:5173"]
}

inputs = {
  deploy_branches          = local.deploy_branches
  image_expiration_days    = local.image_expiration_days
  force_delete             = local.force_delete
  local_tunnel             = local.local_tunnel
  xray_enabled             = local.xray_enabled
  otel_sampling_percentage = local.otel_sampling_percentage
  callback_urls            = local.cognito_callback_urls
  logout_urls              = local.cognito_logout_urls
}
