locals {
  lambda_runtime = "python3.12"
  lambda_handler = "lambda_handler.lambda_handler"

  lambda_name         = "${var.environment}-${var.project_name}-${var.lambda_name}"
  lambda_code_zip_key = "${var.lambda_version}/${var.lambda_name}.zip"

  use_custom_config     = var.deploy_strategy != "all_at_once"
  builtin_all_at_once   = "CodeDeployDefault.LambdaAllAtOnce"
  custom_config_name    = "${local.lambda_name}-${var.deploy_strategy}-${var.deploy_percentage}-${var.deploy_interval_minutes}m"
  effective_config_name = local.use_custom_config ? local.custom_config_name : local.builtin_all_at_once

  pc_fixed_count = try(var.provisioned_concurrency.fixed_count, 0)
  pc_util_min    = try(var.provisioned_concurrency.util_min, 0)
  pc_util_max    = try(var.provisioned_concurrency.util_max, 0)
  pc_util_target = try(var.provisioned_concurrency.util_target, 0.7)
  pc_in_cd       = try(var.provisioned_concurrency.util_scale_in_cd, 60)
  pc_out_cd      = try(var.provisioned_concurrency.util_scale_out_cd, 30)

  pc_fixed_on = local.pc_fixed_count > 0
  pc_util_on  = !local.pc_fixed_on && (local.pc_util_min > 0 || local.pc_util_max > 0)

  pc_resource_id = "function:${aws_lambda_function.lambda.function_name}:${aws_lambda_alias.live.name}"
}
