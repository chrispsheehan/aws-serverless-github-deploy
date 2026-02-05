include {
  path = find_in_parent_folders("root.hcl")
}

inputs = {
  sqs_dlq_alarm_threshold           = 5
  sqs_dlq_alarm_evaluation_periods  = 3
  sqs_dlq_alarm_datapoints_to_alarm = 3
  deployment_config = {
    strategy         = "canary"
    percentage       = 10
    interval_minutes = 5 # this should be > the CloudWatch alarm evaluation period to ensure we catch the alarm if it triggers
  }
}

terraform {
  source = "../../../../modules//aws//consumer"
}
