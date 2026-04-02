module "service_consumer" {
  source = "../_shared/service"

  vpc_name   = var.vpc_name
  aws_region = var.aws_region

  state_bucket   = var.state_bucket
  environment    = var.environment
  container_port = var.container_port

  xray_enabled = var.xray_enabled
  local_tunnel = var.local_tunnel

  connection_type     = "internal"
  task_definition_arn = data.terraform_remote_state.task_consumer.outputs.task_definition_arn
  service_name        = data.terraform_remote_state.task_consumer.outputs.service_name

  desired_task_count = 1
  scaling_strategy = {
    max_scaled_task_count = 4
    sqs = {
      scale_out_threshold  = 10  # Start scaling at 10 msgs avg
      scale_in_threshold   = 2   # Scale in below 2 msgs avg  
      scale_out_adjustment = 2   # Add 2 tasks at once
      scale_in_adjustment  = 1   # Remove 1 task
      cooldown_out         = 60  # 1min cooldown (more stable)
      cooldown_in          = 300 # 5min cooldown (prevent flapping)
      queue_name           = data.terraform_remote_state.sqs_consumer.outputs.sqs_queue_name
    }
  }
}
