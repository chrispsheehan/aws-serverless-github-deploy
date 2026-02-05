locals {
  sqs_chunk_size = 5
  lambda_name    = "${var.environment}-${var.project_name}-consumer"
  sqs_queue_name = "${var.project_name}-${var.environment}-consumer-queue"
  sqs_dlq_name   = "${var.project_name}-${var.environment}-consumer-dlq"

  alarm_period_seconds     = 60
  alarm_window_minutes     = ceil((local.alarm_period_seconds * var.sqs_dlq_alarm_evaluation_periods) / 60)
  codedeploy_interval_mins = local.alarm_window_minutes + 2 # add a buffer to ensure we wait long enough for alarms to trigger if they will
}