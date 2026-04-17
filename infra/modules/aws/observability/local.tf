locals {
  dashboard_name     = "${var.environment}-${var.project_name}-observability"
  lambda_logs_source = "/aws/lambda/${var.environment}-${var.project_name}-"
  ecs_logs_source    = "/ecs/ecs-"
  dashboard_url      = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${local.dashboard_name}"

  lambda_logs_query = join("\n", [
    "SOURCE '${local.lambda_logs_source}'",
    "fields @timestamp, level, event, request_id, message, @log",
    "| sort @timestamp desc",
    "| limit 100",
  ])

  ecs_app_logs_query = join("\n", [
    "SOURCE '${local.ecs_logs_source}'",
    "fields @timestamp, level, event, request_id, message_id, service, path, route, message, @log",
    "| filter @log not like /\\/otel$/",
    "| sort @timestamp desc",
    "| limit 100",
  ])

  ecs_otel_logs_query = join("\n", [
    "SOURCE '${local.ecs_logs_source}'",
    "fields @timestamp, @message, @log",
    "| filter @log like /\\/otel$/",
    "| sort @timestamp desc",
    "| limit 100",
  ])
}
