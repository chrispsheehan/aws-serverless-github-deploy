include {
  path = find_in_parent_folders("root.hcl")
}

inputs = {
  sqs_dlq_alarm_threshold           = 5
  sqs_dlq_alarm_evaluation_periods  = 1
  sqs_dlq_alarm_datapoints_to_alarm = 1
}

terraform {
  source = "../../../../modules//aws//consumer"
}
