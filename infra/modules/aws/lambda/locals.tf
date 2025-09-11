locals {
  lambda_runtime = "python3.12"
  lambda_handler = "lambda_handler.lambda_handler"

  lambda_name         = "${var.environment}-${var.project_name}-${var.lambda_name}"
  lambda_code_zip_key = "${var.lambda_version}/${var.lambda_name}.zip"

  deploy_all_at_once_type = "AllAtOnce"
  deploy_canary_type      = "TimeBasedCanary"
  deploy_linear_type      = "TimeBasedLinear"

  deploy_config_type_map = {
    all_at_once = local.deploy_all_at_once_type
    canary      = local.deploy_canary_type
    linear      = local.deploy_linear_type
  }
  deploy_config = {
    type    = local.deploy_config_type_map[var.deployment_config.strategy]
    percent = var.deployment_config.percentage
    minutes = var.deployment_config.interval_minutes
  }

  fixed_mode           = try(var.provisioned_config.fixed != null, true)
  pc_fixed_count       = try(var.provisioned_config.fixed, 0)
  pc_min_capacity      = try(var.provisioned_config.auto_scale.min, 0)
  pc_max_capacity      = try(var.provisioned_config.auto_scale.max, 0)
  pc_trigger_percent   = try(var.provisioned_config.auto_scale.trigger_percent, var.provisioned_config_defaults.trigger_percent) / 100
  pc_cool_down_seconds = try(var.provisioned_config.auto_scale.cool_down_seconds, var.provisioned_config_defaults.cool_down_seconds)
}
