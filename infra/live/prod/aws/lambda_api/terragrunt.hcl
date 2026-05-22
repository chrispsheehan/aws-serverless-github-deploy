include "root" {
  path = find_in_parent_folders("root.hcl")
}

dependencies {
  paths = ["../security", "../database"]
}

dependency "network" {
  config_path = "${get_original_terragrunt_dir()}/../network"

  mock_outputs = {
    default_target_group_arn  = "arn:aws:elasticloadbalancing:eu-west-2:111111111111:targetgroup/mock-default/1234567890abcdef"
    load_balancer_arn         = "arn:aws:elasticloadbalancing:eu-west-2:111111111111:loadbalancer/app/mock-internal/1234567890abcdef"
    default_http_listener_arn = "arn:aws:elasticloadbalancing:eu-west-2:111111111111:listener/app/mock-internal/1234567890abcdef/abcdef1234567890"
    load_balancer_arn_suffix  = "app/mock-internal/1234567890abcdef"
    target_group_arn_suffix   = "targetgroup/mock-default/1234567890abcdef"
    internal_invoke_url       = "http://mock-internal-123456.eu-west-2.elb.amazonaws.com"
    api_id                    = "mockapi123"
    api_invoke_url            = "https://mockapi123.execute-api.eu-west-2.amazonaws.com"
    api_execution_arn         = "arn:aws:execute-api:eu-west-2:111111111111:mockapi123"
    api_stage_name            = "$default"
    vpc_link_id               = "vpclink-mock123"
    http_api_authorizer_id    = "auth-mock123"
  }

  mock_outputs_allowed_terraform_commands = ["validate", "plan", "destroy", "init", "show", "graph-dependencies", "output-module-groups"]
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

  mock_outputs_allowed_terraform_commands = ["validate", "plan", "destroy", "init", "show", "graph-dependencies", "output-module-groups"]
}

terraform {
  source = "../../../../modules//aws//lambda_api"
}

inputs = merge(
  {
    network_default_target_group_arn  = dependency.network.outputs.default_target_group_arn
    network_load_balancer_arn         = dependency.network.outputs.load_balancer_arn
    network_default_http_listener_arn = dependency.network.outputs.default_http_listener_arn
    network_load_balancer_arn_suffix  = dependency.network.outputs.load_balancer_arn_suffix
    network_target_group_arn_suffix   = dependency.network.outputs.target_group_arn_suffix
    network_internal_invoke_url       = dependency.network.outputs.internal_invoke_url
    network_api_id                    = dependency.network.outputs.api_id
    network_api_invoke_url            = dependency.network.outputs.api_invoke_url
    network_api_execution_arn         = dependency.network.outputs.api_execution_arn
    network_api_stage_name            = dependency.network.outputs.api_stage_name
    network_vpc_link_id               = dependency.network.outputs.vpc_link_id
    network_http_api_authorizer_id    = dependency.network.outputs.http_api_authorizer_id
  },
  dependency.messaging.outputs,
  {
    api_5xx_alarm_threshold           = 5.0
    api_5xx_alarm_evaluation_periods  = 3
    api_5xx_alarm_datapoints_to_alarm = 3

    deployment_config = {
      strategy         = "canary"
      percentage       = 10
      interval_minutes = 5
    }

    provisioned_config = {
      auto_scale = {
        max                        = 2
        min                        = 1
        trigger_percent            = 20
        scale_in_cooldown_seconds  = 60
        scale_out_cooldown_seconds = 60
      }

      reserved_concurrency = 10
    }
  },
)
