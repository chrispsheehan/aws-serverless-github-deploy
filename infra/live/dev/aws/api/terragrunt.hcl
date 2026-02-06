include {
  path = find_in_parent_folders("root.hcl")
}

inputs = {
  api_5xx_alarm_threshold           = 20.0
  api_5xx_alarm_evaluation_periods  = 2
  api_5xx_alarm_datapoints_to_alarm = 2

  deployment_config = {
    strategy         = "canary"
    percentage       = 10
    interval_minutes = 3 # this should be > the CloudWatch alarm evaluation period to ensure we catch the alarm if it triggers
  }

  provisioned_config = {
    auto_scale = {
      max                        = 2
      min                        = 1 # always have 1 lambda ready to go
      trigger_percent            = 20
      scale_in_cooldown_seconds  = 60
      scale_out_cooldown_seconds = 60
    }

    reserved_concurrency = 10 # limit the amount of concurrent executions to avoid throttling, but allow some bursting
  }
}

terraform {
  source = "../../../../modules//aws//api"
}
