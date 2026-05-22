include "root" {
  path = find_in_parent_folders("root.hcl")
}

dependencies {
  paths = ["../security", "../network", "../database"]
}

dependency "messaging" {
  config_path = "${get_original_terragrunt_dir()}/../messaging"

  mock_outputs = {
    worker_topic_name                    = "mock-worker-events"
    worker_topic_arn                     = "arn:aws:sns:eu-west-2:111111111111:mock-worker-events"
    worker_topic_publish_policy_arn      = "arn:aws:iam::111111111111:policy/mock-worker-topic-publish"
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

  mock_outputs_merge_strategy_with_state = "shallow"
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "destroy", "init", "show", "graph-dependencies", "output-module-groups"]
}

dependency "code_bucket" {
  config_path = "${get_original_terragrunt_dir()}/../code_bucket"

  mock_outputs = {
    bucket = "mock-code-bucket"
  }

  mock_outputs_merge_strategy_with_state = "shallow"
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "destroy", "init", "show", "graph-dependencies", "output-module-groups"]
}

terraform {
  source = "../../../../modules//aws//lambda_worker"
}

inputs = merge(
  {
    code_bucket = dependency.code_bucket.outputs.bucket
  },
  dependency.messaging.outputs,
  {
    sqs_dlq_alarm_threshold           = 1 # fail when any messages are in the DLQ (quick fail for testing)
    sqs_dlq_alarm_evaluation_periods  = 1
    sqs_dlq_alarm_datapoints_to_alarm = 1

    deployment_config = {
      strategy         = "canary"
      percentage       = 50
      interval_minutes = 3 # this should be > the CloudWatch alarm evaluation period to ensure we catch the alarm if it triggers
    }

    provisioned_config = {
      sqs_scale = {
        min                        = 1
        max                        = 5
        visible_messages           = 10
        scale_in_cooldown_seconds  = 60
        scale_out_cooldown_seconds = 60
      }
    }
  },
)
