locals {
  log_retention_days = 14
  deploy_branches    = ["main"]
}

inputs = {
  log_retention_days = local.log_retention_days
  deploy_branches    = local.deploy_branches
  otel_sample_rate   = 0.1 # 10% of traces sampled
}
