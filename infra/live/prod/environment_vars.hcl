locals {
  log_retention_days    = 14
  deploy_branches       = ["main"]
  cognito_callback_urls = ["http://localhost:5173"]
  cognito_logout_urls   = ["http://localhost:5173"]
}

inputs = {
  log_retention_days = local.log_retention_days
  deploy_branches    = local.deploy_branches
  otel_sample_rate   = 0.1 # 10% of traces sampled
  callback_urls      = local.cognito_callback_urls
  logout_urls        = local.cognito_logout_urls
}
