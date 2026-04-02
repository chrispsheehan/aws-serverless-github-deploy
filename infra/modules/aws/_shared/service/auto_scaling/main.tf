resource "aws_appautoscaling_target" "ecs" {
  count = local.enable_scaling ? 1 : 0

  max_capacity       = var.scaling_strategy.max_scaled_task_count
  min_capacity       = var.initial_task_count
  resource_id        = "service/${var.cluster_name}/${var.service_name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "cpu_scale_in" {
  count              = local.enable_cpu_scaling ? 1 : 0
  name               = "${var.service_name}-cpu-scale-in"
  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.ecs[0].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs[0].service_namespace

  step_scaling_policy_configuration {
    adjustment_type = "ChangeInCapacity"

    step_adjustment {
      scaling_adjustment          = var.scaling_strategy.cpu.scale_in_adjustment
      metric_interval_upper_bound = 0
    }

    cooldown                = var.scaling_strategy.cpu.cooldown_in
    metric_aggregation_type = "Average"
  }
}

resource "aws_appautoscaling_policy" "cpu_scale_out" {
  count              = local.enable_cpu_scaling ? 1 : 0
  name               = "${var.service_name}-cpu-scale-out"
  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.ecs[0].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs[0].service_namespace

  step_scaling_policy_configuration {
    adjustment_type = "ChangeInCapacity"

    step_adjustment {
      scaling_adjustment          = var.scaling_strategy.cpu.scale_out_adjustment
      metric_interval_lower_bound = 0
    }

    cooldown                = var.scaling_strategy.cpu.cooldown_out
    metric_aggregation_type = "Average"
  }
}

resource "aws_cloudwatch_metric_alarm" "cpu_scale_in_alarm" {
  count = local.enable_cpu_scaling ? 1 : 0

  alarm_name          = "${var.service_name}-cpu-scale-in-alarm"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = local.evaluation_periods_cpu_in
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = var.scaling_strategy.cpu.cooldown_in
  statistic           = "Average"
  threshold           = var.scaling_strategy.cpu.scale_in_threshold
  alarm_actions       = [aws_appautoscaling_policy.cpu_scale_in[0].arn]

  dimensions = {
    ClusterName = var.cluster_name
    ServiceName = var.service_name
  }
}

resource "aws_cloudwatch_metric_alarm" "cpu_scale_out_alarm" {
  count = local.enable_cpu_scaling ? 1 : 0

  alarm_name          = "${var.service_name}-cpu-scale-out-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = local.evaluation_periods_cpu_out
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = var.scaling_strategy.cpu.cooldown_out
  statistic           = "Average"
  threshold           = var.scaling_strategy.cpu.scale_out_threshold
  alarm_actions       = [aws_appautoscaling_policy.cpu_scale_out[0].arn]

  dimensions = {
    ClusterName = var.cluster_name
    ServiceName = var.service_name
  }
}

resource "aws_appautoscaling_policy" "sqs_scale_in" {
  count              = local.enable_sqs_scaling ? 1 : 0
  name               = "${var.service_name}-sqs-scale-in"
  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.ecs[0].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs[0].service_namespace

  step_scaling_policy_configuration {
    adjustment_type = "ChangeInCapacity"

    step_adjustment {
      scaling_adjustment          = var.scaling_strategy.sqs.scale_in_adjustment
      metric_interval_upper_bound = 0
    }

    cooldown                = var.scaling_strategy.sqs.cooldown_in
    metric_aggregation_type = "Average"
  }
}

resource "aws_appautoscaling_policy" "sqs_scale_out" {
  count              = local.enable_sqs_scaling ? 1 : 0
  name               = "${var.service_name}-sqs-scale-out"
  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.ecs[0].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs[0].service_namespace

  step_scaling_policy_configuration {
    adjustment_type = "ChangeInCapacity"

    step_adjustment {
      scaling_adjustment          = var.scaling_strategy.sqs.scale_out_adjustment
      metric_interval_lower_bound = 0
    }

    cooldown                = var.scaling_strategy.sqs.cooldown_out
    metric_aggregation_type = "Average"
  }
}

resource "aws_cloudwatch_metric_alarm" "sqs_scale_in_alarm" {
  count = local.enable_sqs_scaling ? 1 : 0

  alarm_name          = "${var.service_name}-sqs-scale-in-alarm"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = local.evaluation_periods_sqs_in
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = var.scaling_strategy.sqs.cooldown_in
  statistic           = "Average"
  threshold           = var.scaling_strategy.sqs.scale_in_threshold
  alarm_actions       = [aws_appautoscaling_policy.sqs_scale_in[0].arn]

  dimensions = {
    QueueName = var.scaling_strategy.sqs.queue_name
  }
}

resource "aws_cloudwatch_metric_alarm" "sqs_scale_out_alarm" {
  count = local.enable_sqs_scaling ? 1 : 0

  alarm_name          = "${var.service_name}-sqs-scale-out-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = local.evaluation_periods_sqs_out
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = var.scaling_strategy.sqs.cooldown_out
  statistic           = "Average"
  threshold           = var.scaling_strategy.sqs.scale_out_threshold
  alarm_actions       = [aws_appautoscaling_policy.sqs_scale_out[0].arn]

  dimensions = {
    QueueName = var.scaling_strategy.sqs.queue_name
  }
}

resource "aws_appautoscaling_policy" "alb_req_per_target" {
  count              = local.enable_alb_scaling ? 1 : 0
  name               = "${var.service_name}-alb-req-per-target"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs[0].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ALBRequestCountPerTarget"

      # ALB ARN suffix: app/<name>/<id>
      # TG ARN suffix: targetgroup/<name>/<id>
      resource_label = "${var.load_balancer_arn_suffix}/${var.target_group_arn_suffix}"
    }

    target_value       = var.scaling_strategy.alb.target_requests_per_task
    scale_in_cooldown  = local.evaluation_periods_alb_in
    scale_out_cooldown = local.evaluation_periods_alb_out
  }
}
