module "service_api" {
  source = "../_shared/service"

  service_name        = var.service_name
  task_definition_arn = var.bootstrap ? "" : data.terraform_remote_state.task_api[0].outputs.task_definition_arn
  container_port      = var.container_port
  root_path           = var.root_path
  connection_type     = var.connection_type

  aws_region         = var.aws_region
  vpc_id             = data.aws_vpc.this.id
  private_subnet_ids = data.aws_subnets.private.ids

  cluster_id            = data.terraform_remote_state.cluster.outputs.cluster_id
  cluster_name          = data.terraform_remote_state.cluster.outputs.cluster_name
  ecs_security_group_id = data.terraform_remote_state.security.outputs.ecs_sg

  default_target_group_arn  = data.terraform_remote_state.network.outputs.default_target_group_arn
  default_http_listener_arn = data.terraform_remote_state.network.outputs.default_http_listener_arn
  load_balancer_arn_suffix  = data.terraform_remote_state.network.outputs.load_balancer_arn_suffix
  target_group_arn_suffix   = data.terraform_remote_state.network.outputs.target_group_arn_suffix

  api_id              = data.terraform_remote_state.network.outputs.api_id
  vpc_link_id         = data.terraform_remote_state.network.outputs.vpc_link_id
  internal_invoke_url = data.terraform_remote_state.network.outputs.internal_invoke_url
  api_invoke_url      = data.terraform_remote_state.network.outputs.api_invoke_url

  bootstrap             = var.bootstrap
  bootstrap_image_uri   = var.bootstrap_image_uri
  xray_enabled          = var.xray_enabled
  local_tunnel          = var.local_tunnel
  wait_for_steady_state = var.wait_for_steady_state

  desired_task_count            = 1
  deployment_strategy           = "blue_green"
  codedeploy_alarm_names        = []
  additional_security_group_ids = []

  scaling_strategy = {
    max_scaled_task_count = 2
  }
}
