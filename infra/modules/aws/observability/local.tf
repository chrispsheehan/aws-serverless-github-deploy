locals {
  dashboard_name = "${var.environment}-${var.project_name}-observability"
  dashboard_url  = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${local.dashboard_name}"

  lambda_log_groups = [
    "/aws/lambda/${var.environment}-${var.project_name}-api",
    "/aws/lambda/${var.environment}-${var.project_name}-lambda-worker",
  ]

  ecs_app_log_groups = [
    "/ecs/ecs-service-api",
    "/ecs/ecs-worker",
  ]

  ecs_otel_log_groups = [
    "/ecs/ecs-service-api/otel",
    "/ecs/ecs-worker/otel",
  ]

  lambda_logs_query = join("\n", [
    join(" | ", [for group in local.lambda_log_groups : "SOURCE '${group}'"]),
    "| filter @type not in ['START', 'END', 'REPORT']",
    "| fields @timestamp, level, event, request_id, message, @log",
    "| filter ispresent(event) or ispresent(level) or ispresent(request_id) or ispresent(message)",
    "| sort @timestamp desc",
    "| limit 100",
  ])

  ecs_app_logs_query = join("\n", [
    join(" | ", [for group in local.ecs_app_log_groups : "SOURCE '${group}'"]),
    "| fields @timestamp, level, event, request_id, message_id, service, path, route, message, @log",
    "| filter ispresent(event) or ispresent(level) or ispresent(request_id) or ispresent(message_id) or ispresent(service) or ispresent(message)",
    "| sort @timestamp desc",
    "| limit 100",
  ])

  ecs_otel_logs_query = join("\n", [
    join(" | ", [for group in local.ecs_otel_log_groups : "SOURCE '${group}'"]),
    "| fields @timestamp, @message, @log",
    "| sort @timestamp desc",
    "| limit 100",
  ])
}
