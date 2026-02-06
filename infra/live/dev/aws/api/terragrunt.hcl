include {
  path = find_in_parent_folders("root.hcl")
}

inputs = {
  api_5xx_alarm_threshold           = 20.0
  api_5xx_alarm_evaluation_periods  = 1
  api_5xx_alarm_datapoints_to_alarm = 1

  deployment_config = {
    strategy         = "canary"
    percentage       = 10
    interval_minutes = 3
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
