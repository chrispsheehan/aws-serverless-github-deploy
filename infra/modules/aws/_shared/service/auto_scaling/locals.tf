locals {
  # "Off" is just: both cpu and sqs are null / missing
  enable_cpu_scaling = try(var.scaling_strategy.cpu != null, false)
  enable_sqs_scaling = try(var.scaling_strategy.sqs != null, false)
  enable_alb_scaling = try(var.scaling_strategy.alb != null, false)

  enable_scaling = local.enable_cpu_scaling || local.enable_sqs_scaling || local.enable_alb_scaling

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
}
