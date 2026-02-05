locals {
  lambda_name              = "${var.environment}-${var.project_name}-api"
  apigw_http_5xx_metric    = "5xx"
  api_5xx_alarm_name       = "${local.lambda_name}-api-v2-5xx-rate-critical"
  alarm_period_seconds     = 60
  alarm_window_minutes     = ceil((local.alarm_period_seconds * var.api_5xx_alarm_evaluation_periods) / 60)
  codedeploy_interval_mins = local.alarm_window_minutes + 2 # add a buffer to ensure we wait long enough for alarms to trigger if they will
}