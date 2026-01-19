module "lambda_consumer" {
  source = "../_shared/lambda"

  project_name  = var.project_name
  environment   = var.environment
  lambda_bucket = var.lambda_bucket

  lambda_name    = "consumer"
  lambda_version = var.lambda_version

  deployment_config = {
    strategy = "all_at_once"
  }

  # provisioned_config = {
  #   fixed = 0 # cold starts only
  # }

  provisioned_config = {
    fixed                = 1 # always have 1 lambda ready to go
    reserved_concurrency = 2 # only allow 2 concurrent executions THIS ALSO SERVES AS A LIMIT TO AVOID THROTTLING
  }
}

module "sqs_queue" {
  source = "../_shared/sqs"

  sqs_queue_name = "${var.project_name}-${var.environment}-consumer-queue"
}

resource "aws_lambda_event_source_mapping" "sqs" {
  event_source_arn = module.sqs_queue.sqs_queue_arn
  function_name    = module.sqs_queue.lambda_function_name

  batch_size                         = 500
  maximum_batching_window_in_seconds = 10

  function_response_types = ["ReportBatchItemFailures"]
}