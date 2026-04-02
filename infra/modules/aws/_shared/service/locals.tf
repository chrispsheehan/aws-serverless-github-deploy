locals {
  use_vpc_link = var.connection_type == "vpc_link"

  priority          = parseint(substr(md5(var.service_name), 0, 2), 16) % 90 + 10
  vpc_link_count    = local.use_vpc_link ? 1 : 0
  full_tg_name      = "${var.service_name}-tg"
  target_group_name = length(local.full_tg_name) > 32 ? substr(local.full_tg_name, 0, 32) : local.full_tg_name

  is_default_path   = var.root_path == ""
  health_check_path = local.is_default_path ? "/health" : "/${var.root_path}/health"
  exact_route_key   = local.is_default_path ? "ANY /" : "ANY /${var.root_path}"
  proxy_route_key   = local.is_default_path ? "ANY /{proxy+}" : "ANY /${var.root_path}/{proxy+}"
  target_group_arn  = local.is_default_path ? var.default_target_group_arn : aws_lb_target_group.service_target_group[0].arn

  load_balancers = var.connection_type == "internal_dns" || var.connection_type == "vpc_link" ? [{
    target_group_arn = local.target_group_arn
    container_name   = var.service_name
    container_port   = var.container_port
  }] : []

  enable_cpu_scaling = try(var.scaling_strategy.cpu != null, false)
  enable_sqs_scaling = try(var.scaling_strategy.sqs != null, false)
  enable_alb_scaling = try(var.scaling_strategy.alb != null, false)
  enable_scaling     = local.enable_cpu_scaling || local.enable_sqs_scaling || local.enable_alb_scaling

  evaluation_periods_cpu_out = local.enable_cpu_scaling ? (
    var.scaling_strategy.cpu.cooldown_out <= 60
    ? 1
    : floor(var.scaling_strategy.cpu.cooldown_out / 60)
  ) : null

  evaluation_periods_cpu_in = local.enable_cpu_scaling ? (
    var.scaling_strategy.cpu.cooldown_in <= 60
    ? 1
    : floor(var.scaling_strategy.cpu.cooldown_in / 60)
  ) : null

  evaluation_periods_sqs_out = local.enable_sqs_scaling ? (
    var.scaling_strategy.sqs.cooldown_out <= 60
    ? 1
    : floor(var.scaling_strategy.sqs.cooldown_out / 60)
  ) : null

  evaluation_periods_sqs_in = local.enable_sqs_scaling ? (
    var.scaling_strategy.sqs.cooldown_in <= 60
    ? 1
    : floor(var.scaling_strategy.sqs.cooldown_in / 60)
  ) : null

  evaluation_periods_alb_out = local.enable_alb_scaling ? (
    var.scaling_strategy.alb.cooldown_out <= 60
    ? 1
    : floor(var.scaling_strategy.alb.cooldown_out / 60)
  ) : null

  evaluation_periods_alb_in = local.enable_alb_scaling ? (
    var.scaling_strategy.alb.cooldown_in <= 60
    ? 1
    : floor(var.scaling_strategy.alb.cooldown_in / 60)
  ) : null

  base_url = var.connection_type == "internal" ? null : (
    var.connection_type == "internal_dns"
    ? var.internal_invoke_url
    : var.api_invoke_url
  )
  invoke_url = var.root_path == "" ? local.base_url : "${local.base_url}/${var.root_path}"
}
