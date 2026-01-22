locals {
  lambda_runtime   = "python3.12"
  lambda_handler   = "lambda_handler.lambda_handler"
  compute_platform = "Lambda"

  lambda_name         = "${var.environment}-${var.project_name}-${var.lambda_name}"
  lambda_code_zip_key = "${var.lambda_version}/${var.lambda_name}.zip"
  lambda_appspec_key  = "appspecs/${var.lambda_name}-appspec.zip"

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

  fixed_mode      = try(var.provisioned_config.fixed != null, true) && try(var.provisioned_config.fixed > 0, false)
  auto_scale_mode = try(var.provisioned_config.auto_scale != null, false)
  sqs_scale_mode  = try(var.provisioned_config.sqs_scale != null, false)

  pc_fixed_count    = try(var.provisioned_config.fixed, 0)
  pc_reserved_count = try(var.provisioned_config.reserved_concurrency, 0)

  pc_min_capacity = try(var.provisioned_config.sqs_scale.min, var.provisioned_config.auto_scale.min, 0)
  pc_max_capacity = try(var.provisioned_config.sqs_scale.max, var.provisioned_config.auto_scale.max, 0)

  pc_scale_in_cooldown_seconds  = try(var.provisioned_config.auto_scale.scale_in_cooldown_seconds, var.provisioned_config.sqs_scale.scale_in_cooldown_seconds, 60)
  pc_scale_out_cooldown_seconds = try(var.provisioned_config.auto_scale.scale_out_cooldown_seconds, var.provisioned_config.sqs_scale.scale_out_cooldown_seconds, 60)

  pc_trigger_percent             = try(var.provisioned_config.auto_scale.trigger_percent, 70) / 100
  pc_sqs_target_visible_messages = try(var.provisioned_config.sqs_scale.visible_messages, 0)
  pc_sqs_queue_name              = try(var.provisioned_config.sqs_scale.queue_name, "")
}
