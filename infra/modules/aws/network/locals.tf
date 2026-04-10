locals {
  resource_suffix    = substr(md5("${var.project_name}-${var.environment}"), 0, 8)
  load_balancer_name = "alb-${var.environment}-${local.resource_suffix}"
  target_group_name  = "tg-${var.environment}-${local.resource_suffix}"

  base_interface_endpoints = {
    ecr_api = "ecr.api"
    ecr_dkr = "ecr.dkr"
    logs    = "logs"
  }

  tunnel_interface_endpoints = var.local_tunnel ? {
    ssmmessages = "ssmmessages"
    ec2messages = "ec2messages"
  } : {}

  xray_interface_endpoints = var.xray_enabled ? {
    xray = "xray"
  } : {}

  interface_endpoints = merge(
    local.base_interface_endpoints,
    local.tunnel_interface_endpoints,
    local.xray_interface_endpoints,
  )
}
