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

  deployment_config = {
    strategy = "all_at_once"
  }

  codedeploy_alarm_names = [
    local.sqs_dlq_name
  ]

  provisioned_config = {
    sqs_scale = {
      min                        = 1
      max                        = 5
      visible_messages           = 10
      queue_name                 = module.sqs_queue.sqs_queue_name
      scale_in_cooldown_seconds  = 60
      scale_out_cooldown_seconds = 60
    }
  }
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

resource "aws_cloudwatch_metric_alarm" "dlq_messages_present" {
  alarm_name        = local.sqs_dlq_name
  alarm_description = "Messages present in DLQ ${local.sqs_dlq_name}"
  actions_enabled   = true

  namespace           = "AWS/SQS"
  metric_name         = "ApproximateNumberOfMessagesVisible"
  statistic           = "Sum"
  period              = 60
  evaluation_periods  = 1
  datapoints_to_alarm = 1

  comparison_operator = "GreaterThanThreshold"
  threshold           = 0
  treat_missing_data  = "notBreaching"

  dimensions = {
    QueueName = module.sqs_queue.dead_letter_queue_name
  }
}
