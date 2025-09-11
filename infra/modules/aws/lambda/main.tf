resource "aws_iam_role" "iam_for_lambda" {
  name               = "${local.lambda_name}-iam"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_lambda_function" "lambda" {
  function_name = local.lambda_name
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = local.lambda_handler
  runtime       = local.lambda_runtime

  s3_bucket = data.aws_s3_bucket.lambda_code.bucket
  s3_key    = local.lambda_code_zip_key

  # publish ONE immutable version so we can create an alias
  publish = true

  lifecycle {
    # Do not update on changes to the initial s3 file version
    ignore_changes = [
      s3_bucket,
      s3_key,
      s3_object_version,
    ]
  }
}

resource "aws_cloudwatch_log_group" "lambda_cloudwatch_group" {
  name              = "/aws/lambda/${local.lambda_name}"
  retention_in_days = var.log_retention_days
}

resource "aws_lambda_alias" "live" {
  name             = var.environment
  function_name    = aws_lambda_function.lambda.arn
  function_version = aws_lambda_function.lambda.version

  # CodeDeploy will repoint this alias → ignore drift
  lifecycle {
    ignore_changes = [function_version, routing_config]
  }
}

resource "aws_lambda_provisioned_concurrency_config" "alias_pc_fixed" {
  count = local.fixed_mode && local.pc_fixed_count > 0 ? 1 : 0

  function_name                     = aws_lambda_function.lambda.function_name
  qualifier                         = aws_lambda_alias.live.name
  provisioned_concurrent_executions = local.pc_fixed_count

  depends_on = [aws_lambda_alias.live]
}

resource "aws_codedeploy_app" "app" {
  name             = "${local.lambda_name}-app"
  compute_platform = "Lambda"
}

resource "aws_iam_role" "code_deploy_role" {
  name               = "${local.lambda_name}-codedeploy-role"
  assume_role_policy = data.aws_iam_policy_document.code_deploy_assume.json
}

resource "aws_iam_role_policy" "cd_lambda" {
  name   = "${local.lambda_name}-codedeploy-lambda"
  role   = aws_iam_role.code_deploy_role.id
  policy = data.aws_iam_policy_document.codedeploy_lambda.json
}

resource "aws_codedeploy_deployment_config" "lambda_config" {
  deployment_config_name = "${local.lambda_name}-deploy-config"
  compute_platform       = "Lambda"

  traffic_routing_config {
    type = local.deploy_config.type

    dynamic "time_based_canary" {
      for_each = local.deploy_config.type == local.deploy_canary_type ? [1] : []
      content {
        percentage = local.deploy_config.percent
        interval   = local.deploy_config.minutes
      }
    }

    dynamic "time_based_linear" {
      for_each = local.deploy_config.type == local.deploy_linear_type ? [1] : []
      content {
        percentage = local.deploy_config.percent
        interval   = local.deploy_config.minutes
      }
    }
  }
}

resource "aws_codedeploy_deployment_group" "dg" {
  app_name              = aws_codedeploy_app.app.name
  deployment_group_name = "${local.lambda_name}-dg"
  service_role_arn      = aws_iam_role.code_deploy_role.arn

  deployment_style {
    deployment_type   = "BLUE_GREEN"
    deployment_option = "WITH_TRAFFIC_CONTROL"
  }

  deployment_config_name = aws_codedeploy_deployment_config.lambda_config.deployment_config_name

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE", "DEPLOYMENT_STOP_ON_ALARM"]
  }
}

resource "aws_appautoscaling_target" "pc_target" {
  min_capacity       = local.pc_min_capacity
  max_capacity       = local.pc_max_capacity
  resource_id        = "function:${local.lambda_name}:${var.environment}"
  scalable_dimension = "lambda:function:ProvisionedConcurrency"
  service_namespace  = "lambda"
}

resource "aws_appautoscaling_policy" "pc_policy" {
  count              = local.fixed_mode ? 0 : 1
  name               = "${local.lambda_name}-pc-tt"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.pc_target.resource_id
  scalable_dimension = aws_appautoscaling_target.pc_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.pc_target.service_namespace

  target_tracking_scaling_policy_configuration {
    target_value       = local.pc_trigger_percent
    scale_in_cooldown  = local.pc_min_capacity
    scale_out_cooldown = local.pc_max_capacity
    predefined_metric_specification {
      predefined_metric_type = "LambdaProvisionedConcurrencyUtilization"
    }
  }
}
