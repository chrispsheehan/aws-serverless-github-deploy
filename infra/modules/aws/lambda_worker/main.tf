module "lambda_worker" {
  source = "../_shared/lambda"

  project_name     = var.project_name
  environment      = var.environment
  code_bucket      = var.code_bucket
  otel_sample_rate = var.otel_sample_rate

  lambda_name = local.lambda_name

  environment_variables = {
    DEBUG_DELAY_MS = 500
    CHUNK_SIZE     = local.sqs_chunk_size
  }

  additional_policy_arns = [
    data.terraform_remote_state.worker_messaging.outputs.lambda_worker_queue_read_policy_arn
  ]

  deployment_config = var.deployment_config

  codedeploy_alarm_names = [
    aws_cloudwatch_metric_alarm.dlq_new_messages.alarm_name
  ]

  provisioned_config = try(var.provisioned_config.sqs_scale, null) == null ? var.provisioned_config : merge(
    var.provisioned_config,
    {
      sqs_scale = merge(
        var.provisioned_config.sqs_scale,
        {
          queue_name = data.terraform_remote_state.worker_messaging.outputs.lambda_worker_queue_name
        }
      )
    }
  )
}

resource "aws_lambda_event_source_mapping" "sqs" {
  event_source_arn = data.terraform_remote_state.worker_messaging.outputs.lambda_worker_queue_arn
  function_name    = module.lambda_worker.function_name

  batch_size                         = local.sqs_chunk_size
  maximum_batching_window_in_seconds = 10

  function_response_types = ["ReportBatchItemFailures"]
}

resource "aws_cloudwatch_metric_alarm" "dlq_new_messages" {
  alarm_name        = "${data.terraform_remote_state.worker_messaging.outputs.lambda_worker_dead_letter_queue_name}-new-messages"
  alarm_description = "New messages sent to DLQ ${data.terraform_remote_state.worker_messaging.outputs.lambda_worker_dead_letter_queue_name}"
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
    QueueName = data.terraform_remote_state.worker_messaging.outputs.lambda_worker_dead_letter_queue_name
  }
}
