module "service_api" {
  source = "../_shared/service"

  service_name        = var.service_name
  task_definition_arn = var.bootstrap ? "" : var.task_definition_arn
  container_port      = var.container_port
  root_path           = var.root_path
  connection_type     = var.connection_type

  aws_region          = var.aws_region
  ecr_repository_name = var.ecr_repository_name
  vpc_id              = data.aws_vpc.this.id
  private_subnet_ids  = data.aws_subnets.private.ids

  cluster_id            = var.cluster_id
  cluster_name          = var.cluster_name
  ecs_security_group_id = var.ecs_security_group_id

  default_target_group_arn  = var.network_default_target_group_arn
  load_balancer_arn         = var.network_load_balancer_arn
  default_http_listener_arn = var.network_default_http_listener_arn
  load_balancer_arn_suffix  = var.network_load_balancer_arn_suffix
  target_group_arn_suffix   = var.network_target_group_arn_suffix

  api_id              = var.network_api_id
  vpc_link_id         = var.network_vpc_link_id
  internal_invoke_url = var.network_internal_invoke_url
  api_invoke_url      = var.network_api_invoke_url
  authorization_type  = "JWT"
  authorizer_id       = var.network_http_api_authorizer_id

  bootstrap             = var.bootstrap
  xray_enabled          = var.xray_enabled
  local_tunnel          = var.local_tunnel
  wait_for_steady_state = var.wait_for_steady_state

  desired_task_count            = 1
  deployment_strategy           = "blue_green"
  dedicated_listener_port       = 8080
  codedeploy_alarm_names        = []
  additional_security_group_ids = []

  scaling_strategy = {
    max_scaled_task_count = 2
  }
}
