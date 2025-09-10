locals {
  lambda_runtime = "python3.12"
  lambda_handler = "lambda_handler.lambda_handler"

  lambda_name         = "${var.environment}-${var.project_name}-${var.lambda_name}"
  lambda_code_zip_key = "${var.lambda_version}/${var.lambda_name}.zip"

  use_custom_config     = var.deploy_strategy != "all_at_once"
  builtin_all_at_once   = "CodeDeployDefault.LambdaAllAtOnce"
  custom_config_name    = "${local.lambda_name}-${var.deploy_strategy}-${var.deploy_percentage}-${var.deploy_interval_minutes}m"
  effective_config_name = local.use_custom_config ? local.custom_config_name : local.builtin_all_at_once
}
