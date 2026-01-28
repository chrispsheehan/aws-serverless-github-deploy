module "lambda_consumer" {
  source = "../_shared/lambda"

  project_name  = var.project_name
  environment   = var.environment
  lambda_bucket = var.lambda_bucket

  lambda_name = local.lambda_name

  additional_policy_arns = [
    module.sqs_queue.sqs_queue_read_policy_arn
  ]

  deployment_config = {
    strategy = "all_at_once"
  }

  provisioned_config = {
    fixed = 0 # cold starts only
  }

  # provisioned_config = {
  #   fixed                = 1 # always have 1 lambda ready to go
  #   reserved_concurrency = 2 # only allow 2 concurrent executions THIS ALSO SERVES AS A LIMIT TO AVOID THROTTLING
  # }

  # provisioned_config = {
  #   sqs_scale = {
  #     min                        = 1
  #     max                        = 5
  #     visible_messages           = 100
  #     queue_name                 = module.sqs_queue.sqs_queue_name
  #     scale_in_cooldown_seconds  = 60
  #     scale_out_cooldown_seconds = 60
  #   }
  # }
}

configure a deadletter queue (DLQ) for the SQS queue used by the Lambda consumer

module "sqs_queue" {
  source = "../_shared/sqs"

  sqs_queue_name = "${var.project_name}-${var.environment}-consumer-queue"
}

resource "aws_lambda_event_source_mapping" "sqs" {
  event_source_arn = module.sqs_queue.sqs_queue_arn
  function_name    = module.lambda_consumer.function_name

  batch_size                         = 500
  maximum_batching_window_in_seconds = 10

  function_response_types = ["ReportBatchItemFailures"]
}

resource "aws_cloudwatch_metric_alarm" "dlq_msg_count" {
  alarm_name          = "${local.lambda_name}-${aws_lambda_event_source_mapping.sqs.}-dlq-msg-count"
  alarm_description   = "Alert when DLQ ${var.dlq_queue_name} has any visible messages"
  namespace           = "AWS/SQS"
  metric_name         = "ApproximateNumberOfMessagesVisible"
  statistic           = "Sum"
  period              = 60
  evaluation_periods  = 1
  datapoints_to_alarm = 1
  comparison_operator = "GreaterThanThreshold"
  threshold           = 0.5
  treat_missing_data  = "notBreaching"

  dimensions = {
    QueueName = var.dlq_queue_name
  }

  # optional SNS notification
  dynamic "alarm_actions" {
    for_each = var.dlq_alert_sns_arn != "" ? [1] : []
    content {
      alarm_actions = [var.dlq_alert_sns_arn]
    }
  }
}
