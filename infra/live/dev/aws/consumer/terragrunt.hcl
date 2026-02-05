include {
  path = find_in_parent_folders("root.hcl")
}

inputs = {
  sqs_dlq_alarm_threshold           = 5
  sqs_dlq_alarm_evaluation_periods  = 1
  sqs_dlq_alarm_datapoints_to_alarm = 2
  deployment_config = {
    strategy         = "canary"
    percentage       = 10
    interval_minutes = 3 # this should be > the CloudWatch alarm evaluation period to ensure we catch the alarm if it triggers
  }
}

terraform {
  source = "../../../../modules//aws//consumer"
}
