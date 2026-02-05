module "lambda_api" {
  source = "../_shared/lambda"

  project_name  = var.project_name
  environment   = var.environment
  lambda_bucket = var.lambda_bucket

  lambda_name = local.lambda_name

  environment_variables = {
    DEBUG_DELAY_MS = 500
  }

  deployment_config = var.deployment_config

  codedeploy_alarm_names = [
    local.api_5xx_alarm_name
  ]

  provisioned_config = var.provisioned_config
}

resource "aws_apigatewayv2_api" "http_api" {
  name          = "${module.lambda_api.name}-http"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "lambda_proxy" {
  api_id                 = aws_apigatewayv2_api.http_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = module.lambda_api.alias_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "root" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "ANY /"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_proxy.id}"
}

resource "aws_apigatewayv2_route" "proxy" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "ANY /{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_proxy.id}"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.http_api.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_lambda_permission" "allow_invoke" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_api.alias_arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*" # all routes/stages
}

resource "aws_cloudwatch_metric_alarm" "api_5xx_rate" {
  alarm_name        = local.api_5xx_alarm_name
  alarm_description = "HTTP API (v2) 5xx error rate > ${var.api_5xx_alarm_threshold}% for ${var.api_5xx_alarm_evaluation_periods} minute(s) ${var.api_5xx_alarm_datapoints_to_alarm} times"
  actions_enabled   = true

  comparison_operator = "GreaterThanThreshold"
  threshold           = var.api_5xx_alarm_threshold           # This is the value your metric is compared against
  evaluation_periods  = var.api_5xx_alarm_evaluation_periods  # This is how many consecutive periods CloudWatch looks at when deciding the alarm state.
  datapoints_to_alarm = var.api_5xx_alarm_datapoints_to_alarm # This is how many of those evaluated periods must be breaching to trigger ALARM.
  treat_missing_data  = "notBreaching"

  #
  # Metric math: (5xx / count) * 100
  # Guarded to avoid NaN/Inf when count is 0 or very low
  #
  metric_query {
    id          = "e"
    label       = "5xxErrorRate"
    return_data = true
    expression  = "IF(mcount < 1, 0, (m5xx / mcount) * 100)"
  }

  #
  # API Gateway v2 – 5XX errors
  #
  metric_query {
    id = "m5xx"
    metric {
      namespace   = "AWS/ApiGateway"
      metric_name = local.apigw_http_5xx_metric
      stat        = "Sum"
      period      = 60

      dimensions = {
        ApiId = aws_apigatewayv2_api.http_api.id
        Stage = aws_apigatewayv2_stage.default.name
      }
    }
  }

  #
  # API Gateway v2 – total request count
  #
  metric_query {
    id = "mcount"
    metric {
      namespace   = "AWS/ApiGateway"
      metric_name = "Count"
      stat        = "Sum"
      period      = 60

      dimensions = {
        ApiId = aws_apigatewayv2_api.http_api.id
        Stage = aws_apigatewayv2_stage.default.name
      }
    }
  }
}
