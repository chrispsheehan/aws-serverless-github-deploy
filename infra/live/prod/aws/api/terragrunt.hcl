include {
  path = find_in_parent_folders("root.hcl")
}

inputs = {
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
}

terraform {
  source = "../../../../modules//aws//api"
}
