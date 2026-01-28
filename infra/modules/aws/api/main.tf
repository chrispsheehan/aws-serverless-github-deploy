module "lambda_api" {
  source = "../_shared/lambda"

  project_name  = var.project_name
  environment   = var.environment
  lambda_bucket = var.lambda_bucket

  lambda_name = local.lambda_name

  environment_variables = {
    DEBUG_DELAY_MS = 500
  }

  deployment_config = {
    strategy = "all_at_once"
  }
  codedeploy_alarm_names = [
    local.api_5xx_alarm_name
  ]

  provisioned_config = {
    fixed = 0 # cold starts only
  }

  # provisioned_config = {
  #   fixed                = 1 # always have 1 lambda ready to go
  #   reserved_concurrency = 2 # only allow 2 concurrent executions THIS ALSO SERVES AS A LIMIT TO AVOID THROTTLING
  # }

  # provisioned_config = {
  #   auto_scale = {
  #     max                        = 2
  #     min                        = 1 # always have 1 lambda ready to go
  #     trigger_percent            = 20
  #     scale_in_cooldown_seconds  = 60
  #     scale_out_cooldown_seconds = 60
  #   }

  #   reserved_concurrency = 10 # limit the amount of concurrent executions to avoid throttling, but allow some bursting
  # }
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
  alarm_name          = local.api_5xx_alarm_name
  alarm_description   = "HTTP API (v2) 5xx error rate > 0.5% for 1 minute"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 0.5
  evaluation_periods  = 1
  datapoints_to_alarm = 1
  treat_missing_data  = "notBreaching"
  actions_enabled     = true

  metric_query {
    id          = "e"
    expression  = "(m5xx / mcount) * 100"
    label       = "5xxErrorRate"
    return_data = true
  }

  metric_query {
    id = "m5xx"
    metric {
      namespace   = "AWS/ApiGateway"
      metric_name = "5XXError"
      period      = 60
      stat        = "Sum"
      dimensions = {
        ApiId = aws_apigatewayv2_api.http_api.id
      }
    }
  }

  metric_query {
    id = "mcount"
    metric {
      namespace   = "AWS/ApiGateway"
      metric_name = "Count"
      period      = 60
      stat        = "Sum"
      dimensions = {
        ApiId = aws_apigatewayv2_api.http_api.id
      }
    }
  }
}

