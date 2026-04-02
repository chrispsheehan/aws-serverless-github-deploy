locals {
  priority       = parseint(substr(md5(var.service_name), 0, 2), 16) % 90 + 10
  vpc_link_count = var.internal_only ? 1 : 0

  full_tg_name      = "${var.service_name}-tg"
  target_group_name = length(local.full_tg_name) > 32 ? substr(local.full_tg_name, 0, 32) : local.full_tg_name

  is_default_path   = var.root_path == ""
  health_check_path = local.is_default_path ? "/health" : "/${var.root_path}/health"

  target_group_arn = local.is_default_path ? var.default_target_group_arn : aws_lb_target_group.service_target_group[0].arn
}
