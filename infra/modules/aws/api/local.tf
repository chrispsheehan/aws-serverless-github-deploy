locals {
  lambda_name           = "${var.environment}-${var.project_name}-api"
  apigw_http_5xx_metric = "5xx"
  api_5xx_alarm_name    = "${local.lambda_name}-api-v2-5xx-rate-critical"
}