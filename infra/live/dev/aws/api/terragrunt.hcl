include {
  path = find_in_parent_folders("root.hcl")
}

inputs = {
  api_5xx_alarm_threshold           = 20.0
  api_5xx_alarm_evaluation_periods  = 3
  api_5xx_alarm_datapoints_to_alarm = 3
}

terraform {
  source = "../../../../modules//aws//api"
}
