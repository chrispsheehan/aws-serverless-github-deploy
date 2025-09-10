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
  count                  = local.use_custom_config ? 1 : 0
  deployment_config_name = local.custom_config_name
  compute_platform       = "Lambda"

  traffic_routing_config {
    type = var.deploy_strategy == "canary" ? "TimeBasedCanary" : "TimeBasedLinear"

    dynamic "time_based_canary" {
      for_each = var.deploy_strategy == "canary" ? [1] : []
      content {
        percentage = var.deploy_percentage
        interval   = var.deploy_interval_minutes
      }
    }

    dynamic "time_based_linear" {
      for_each = var.deploy_strategy == "linear" ? [1] : []
      content {
        percentage = var.deploy_percentage
        interval   = var.deploy_interval_minutes
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

  deployment_config_name = local.use_custom_config ? aws_codedeploy_deployment_config.lambda_config[0].deployment_config_name : local.effective_config_name

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE", "DEPLOYMENT_STOP_ON_ALARM"]
  }
}
