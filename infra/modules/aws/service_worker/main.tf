module "service_worker" {
  source = "../_shared/service"

  service_name        = var.service_name
  task_definition_arn = local.task_definition_arn
  container_port      = var.container_port
  root_path           = var.root_path
  connection_type     = var.connection_type

  aws_region         = var.aws_region
  vpc_id             = data.aws_vpc.this.id
  private_subnet_ids = data.aws_subnets.private.ids

  cluster_id            = var.cluster_id
  cluster_name          = var.cluster_name
  ecs_security_group_id = var.ecs_security_group_id

  default_target_group_arn  = var.network_default_target_group_arn
  default_http_listener_arn = var.network_default_http_listener_arn
  load_balancer_arn_suffix  = var.network_load_balancer_arn_suffix
  target_group_arn_suffix   = var.network_target_group_arn_suffix

  api_id              = var.network_api_id
  vpc_link_id         = var.network_vpc_link_id
  internal_invoke_url = var.network_internal_invoke_url
  api_invoke_url      = var.network_api_invoke_url

  bootstrap             = var.bootstrap
  xray_enabled          = var.xray_enabled
  local_tunnel          = var.local_tunnel
  wait_for_steady_state = var.wait_for_steady_state

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
      queue_name           = local.autoscaling_queue_name
    }
  }
}
