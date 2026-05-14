dependency "worker_messaging" {
  config_path = "${get_original_terragrunt_dir()}/../worker_messaging"

  mock_outputs = {
    sns_topic_name                       = "mock-worker-events"
    sns_topic_arn                        = "arn:aws:sns:eu-west-2:111111111111:mock-worker-events"
    lambda_worker_queue_name             = "mock-lambda-worker-queue"
    lambda_worker_queue_arn              = "arn:aws:sqs:eu-west-2:111111111111:mock-lambda-worker-queue"
    lambda_worker_queue_url              = "https://sqs.eu-west-2.amazonaws.com/111111111111/mock-lambda-worker-queue"
    lambda_worker_queue_read_policy_arn  = "arn:aws:iam::111111111111:policy/mock-lambda-worker-queue-read"
    lambda_worker_dead_letter_queue_name = "mock-lambda-worker-dlq"
    lambda_worker_dead_letter_queue_url  = "https://sqs.eu-west-2.amazonaws.com/111111111111/mock-lambda-worker-dlq"
    ecs_worker_queue_name                = "mock-ecs-worker-queue"
    ecs_worker_queue_url                 = "https://sqs.eu-west-2.amazonaws.com/111111111111/mock-ecs-worker-queue"
    ecs_worker_queue_read_policy_arn     = "arn:aws:iam::111111111111:policy/mock-ecs-worker-queue-read"
  }

  mock_outputs_allowed_terraform_commands = ["validate", "plan", "destroy", "init", "show"]
}

inputs = {
  worker_topic_name                    = dependency.worker_messaging.outputs.sns_topic_name
  worker_topic_arn                     = dependency.worker_messaging.outputs.sns_topic_arn
  lambda_worker_queue_name             = dependency.worker_messaging.outputs.lambda_worker_queue_name
  lambda_worker_queue_arn              = dependency.worker_messaging.outputs.lambda_worker_queue_arn
  lambda_worker_queue_url              = dependency.worker_messaging.outputs.lambda_worker_queue_url
  lambda_worker_queue_read_policy_arn  = dependency.worker_messaging.outputs.lambda_worker_queue_read_policy_arn
  lambda_worker_dead_letter_queue_name = dependency.worker_messaging.outputs.lambda_worker_dead_letter_queue_name
  lambda_worker_dead_letter_queue_url  = dependency.worker_messaging.outputs.lambda_worker_dead_letter_queue_url
  ecs_worker_queue_name                = dependency.worker_messaging.outputs.ecs_worker_queue_name
  ecs_worker_queue_url                 = dependency.worker_messaging.outputs.ecs_worker_queue_url
  ecs_worker_queue_read_policy_arn     = dependency.worker_messaging.outputs.ecs_worker_queue_read_policy_arn
}
