resource "aws_cloudwatch_dashboard" "observability" {
  dashboard_name = local.dashboard_name

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "text"
        x      = 0
        y      = 0
        width  = 24
        height = 2
        properties = {
          markdown = <<-EOT
          # Runtime Logs
          Recent Lambda, ECS app, and ECS OTEL logs for `${var.environment}` in `${var.aws_region}`.
          EOT
        }
      },
      {
        type   = "log"
        x      = 0
        y      = 2
        width  = 24
        height = 8
        properties = {
          title  = "Lambda Logs"
          region = var.aws_region
          view   = "table"
          query  = local.lambda_logs_query
        }
      },
      {
        type   = "log"
        x      = 0
        y      = 10
        width  = 24
        height = 8
        properties = {
          title  = "ECS App Logs"
          region = var.aws_region
          view   = "table"
          query  = local.ecs_app_logs_query
        }
      },
      {
        type   = "log"
        x      = 0
        y      = 18
        width  = 24
        height = 8
        properties = {
          title  = "ECS OTEL Logs"
          region = var.aws_region
          view   = "table"
          query  = local.ecs_otel_logs_query
        }
      },
    ]
  })
}
