locals {
  resource_suffix    = substr(md5("${var.project_name}-${var.environment}"), 0, 8)
  load_balancer_name = "alb-${var.environment}-${local.resource_suffix}"
  target_group_name  = "tg-${var.environment}-${local.resource_suffix}"
}
