include {
  path = find_in_parent_folders("root.hcl")
}

locals {
  aws_account_id = get_aws_account_id()
  sqs_queue_name = "${local.aws_account_id}-dev-serverless-consumer-queue"
}

inputs = {
  sqs_queue_name = local.sqs_queue_name

  sqs_dlq_alarm_threshold           = 5 # fail when there are 5 messages in the DLQ
  sqs_dlq_alarm_evaluation_periods  = 3
  sqs_dlq_alarm_datapoints_to_alarm = 3

  deployment_config = {
    strategy = "all_at_once"
  }

  provisioned_config = {
    sqs_scale = {
      min                        = 1
      max                        = 5
      visible_messages           = 10
      queue_name                 = local.sqs_queue_name
      scale_in_cooldown_seconds  = 60
      scale_out_cooldown_seconds = 60
    }
  }
}

terraform {
  source = "../../../../modules//aws//consumer"
}
