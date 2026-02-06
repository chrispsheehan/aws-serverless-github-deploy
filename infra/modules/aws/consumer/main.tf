module "lambda_consumer" {
  source = "../_shared/lambda"

  project_name  = var.project_name
  environment   = var.environment
  lambda_bucket = var.lambda_bucket

  lambda_name = local.lambda_name

  environment_variables = {
    DEBUG_DELAY_MS = 500
    CHUNK_SIZE     = local.sqs_chunk_size
  }

  additional_policy_arns = [
    module.sqs_queue.sqs_queue_read_policy_arn
  ]

  deployment_config = var.deployment_config

  codedeploy_alarm_names = [
    local.sqs_dlq_name
  ]

  provisioned_config = var.provisioned_config
}

# configure a deadletter queue (DLQ) for the SQS queue used by the Lambda consumer

module "sqs_queue" {
  source = "../_shared/sqs"

  sqs_queue_name = local.sqs_queue_name
  sqs_dlq_name   = local.sqs_dlq_name
}

resource "aws_lambda_event_source_mapping" "sqs" {
  event_source_arn = module.sqs_queue.sqs_queue_arn
  function_name    = module.lambda_consumer.function_name

  batch_size                         = local.sqs_chunk_size
  maximum_batching_window_in_seconds = 10

  function_response_types = ["ReportBatchItemFailures"]
}

resource "aws_cloudwatch_metric_alarm" "dlq_new_messages" {
  alarm_name        = "${local.sqs_dlq_name}-new-messages"
  alarm_description = "New messages sent to DLQ ${local.sqs_dlq_name}"
  actions_enabled   = true

  namespace   = "AWS/SQS"
  metric_name = "NumberOfMessagesSent"
  statistic   = "Sum"
  period      = 60 # most aws metrics are emitted at 1-minute intervals, so using a shorter period can lead to more volatile alarms

  evaluation_periods  = var.sqs_dlq_alarm_evaluation_periods
  datapoints_to_alarm = var.sqs_dlq_alarm_datapoints_to_alarm

  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = var.sqs_dlq_alarm_threshold
  treat_missing_data  = "notBreaching"

  dimensions = {
    QueueName = local.sqs_dlq_name
  }
}
