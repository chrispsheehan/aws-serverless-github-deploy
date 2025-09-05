locals {
  log_retention_days = 14
  deploy_branches    = ["main"]
}

inputs = {
  log_retention_days = local.log_retention_days
  deploy_branches    = local.deploy_branches
}
