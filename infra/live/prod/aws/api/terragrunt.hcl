include {
  path = find_in_parent_folders("root.hcl")
}

inputs = {
  api_5xx_alarm_threshold           = 5.0
  api_5xx_alarm_evaluation_periods  = 1
  api_5xx_alarm_datapoints_to_alarm = 1
}

terraform {
  source = "../../../../modules//aws//api"
}
