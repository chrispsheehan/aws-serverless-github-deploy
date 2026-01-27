resource "aws_iam_role" "iam_for_lambda" {
  name               = "${local.lambda_name}-iam"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "additional_iam_attachments" {
  for_each = { for idx, arn in var.additional_policy_arns : idx => arn }

  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = each.value
}

resource "aws_s3_object" "bootstrap_lambda_zip" {
  bucket = data.aws_s3_bucket.lambda_code.bucket
  key    = local.lambda_bootstrap_zip_key

  source = data.archive_file.bootstrap_lambda.output_path
  etag   = data.archive_file.bootstrap_lambda.output_md5

  content_type = "application/zip"
}

resource "aws_lambda_function" "lambda" {
  function_name = local.lambda_name
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = local.lambda_handler
  runtime       = local.lambda_runtime

  reserved_concurrent_executions = local.pc_reserved_count

  s3_bucket = data.aws_s3_bucket.lambda_code.bucket
  s3_key    = aws_s3_object.bootstrap_lambda_zip.key

  # publish ONE immutable version so we can create an alias
  publish = true

  # tags for identifying the code deploy app and its deployment config. Used in CI/CD pipelines.
  tags = {
    CodeDeployApplication = aws_codedeploy_app.app.name
    CodeDeployGroup       = aws_codedeploy_deployment_group.dg.deployment_group_name
    DeploymentStrategy    = local.deploy_config.type
  }

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
  count = local.fixed_mode && coalesce(local.pc_fixed_count, 0) > 0 ? 1 : 0

  function_name                     = aws_lambda_function.lambda.function_name
  qualifier                         = aws_lambda_alias.live.name
  provisioned_concurrent_executions = local.pc_fixed_count

  depends_on = [aws_lambda_alias.live]
}

resource "aws_codedeploy_app" "app" {
  name             = "${local.lambda_name}-app"
  compute_platform = local.compute_platform
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
  compute_platform       = local.compute_platform

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

  depends_on = [aws_lambda_alias.live]
}

resource "aws_appautoscaling_policy" "pc_policy" {
  count              = local.auto_scale_mode ? 1 : 0
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

resource "aws_appautoscaling_policy" "pc_sqs_policy" {
  count              = local.sqs_scale_mode ? 1 : 0
  name               = "${local.lambda_name}-pc-sqs-depth-tt"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.pc_target.resource_id
  scalable_dimension = aws_appautoscaling_target.pc_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.pc_target.service_namespace

  target_tracking_scaling_policy_configuration {
    # Example: try to keep ~1000 visible messages in the queue.
    # Tune this based on your batch size + desired drain speed.
    target_value = local.pc_sqs_target_visible_messages

    scale_in_cooldown  = local.pc_scale_in_cooldown_seconds
    scale_out_cooldown = local.pc_scale_out_cooldown_seconds

    customized_metric_specification {
      metric_name = "ApproximateNumberOfMessagesVisible"
      namespace   = "AWS/SQS"
      statistic   = "Average"
      unit        = "Count"

      dimensions {
        name  = "QueueName"
        value = local.pc_sqs_queue_name
      }
    }
  }
}
