locals {
  lambda_name        = "${var.environment}-${var.project_name}-api"
  api_5xx_alarm_name = "${local.lambda_name}-api-v2-5xx-rate-critical"
}