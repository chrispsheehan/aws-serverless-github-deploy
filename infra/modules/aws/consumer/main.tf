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

  sqs_queue_name = "${var.project_name}-${var.environment}-consumer-queue"
}

resource "aws_lambda_event_source_mapping" "sqs" {
  event_source_arn = module.sqs_queue.sqs_queue_arn
  function_name    = module.lambda_consumer.function_name

  batch_size                         = local.sqs_chunk_size
  maximum_batching_window_in_seconds = 10

  function_response_types = ["ReportBatchItemFailures"]
}
