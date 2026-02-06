include {
  path = find_in_parent_folders("root.hcl")
}

locals {
  aws_account_id = get_aws_account_id()
  sqs_queue_name = "${local.aws_account_id}-dev-serverless-consumer-queue"
}

inputs = {
  sqs_queue_name = local.sqs_queue_name

  sqs_dlq_alarm_threshold           = 5
  sqs_dlq_alarm_evaluation_periods  = 1
  sqs_dlq_alarm_datapoints_to_alarm = 2

  deployment_config = {
    strategy         = "canary"
    percentage       = 10
    interval_minutes = 3 # this should be > the CloudWatch alarm evaluation period to ensure we catch the alarm if it triggers
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
