resource "aws_iam_role" "bootstrap_execution" {
  count = var.bootstrap ? 1 : 0

  name               = "${var.service_name}-bootstrap-ecs-task-execution-role"
  assume_role_policy = data.aws_iam_policy_document.bootstrap_assume_role.json
}

resource "aws_iam_role_policy_attachment" "bootstrap_execution" {
  count = var.bootstrap ? 1 : 0

  role       = aws_iam_role.bootstrap_execution[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_ecs_task_definition" "bootstrap" {
  count = var.bootstrap ? 1 : 0

  family                   = "${var.service_name}-bootstrap-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.bootstrap_execution[0].arn

  runtime_platform {
    cpu_architecture        = "X86_64"
    operating_system_family = "LINUX"
  }

  container_definitions = local.bootstrap_container_definitions
}

resource "aws_lb_target_group" "service_target_group" {
  count = local.is_default_path ? 0 : 1

  name        = local.target_group_name
  port        = var.container_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  health_check {
    path                = local.health_check_path
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    port                = "traffic-port"
    protocol            = "HTTP"
  }
}

resource "aws_lb_listener_rule" "service" {
  count = local.is_default_path ? 0 : 1

  listener_arn = var.default_http_listener_arn
  priority     = local.priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.service_target_group[0].arn
  }

  condition {
    path_pattern {
      values = ["/${var.root_path}/*"]
    }
  }
}

resource "aws_apigatewayv2_route" "service_exact" {
  count = local.vpc_link_count

  api_id    = var.api_id
  route_key = local.exact_route_key

  target = "integrations/${aws_apigatewayv2_integration.service[0].id}"
}

resource "aws_apigatewayv2_route" "service_proxy" {
  count = local.vpc_link_count

  api_id    = var.api_id
  route_key = local.proxy_route_key

  target = "integrations/${aws_apigatewayv2_integration.service[0].id}"
}

resource "aws_apigatewayv2_integration" "service" {
  count = local.vpc_link_count

  api_id                 = var.api_id
  connection_id          = var.vpc_link_id
  connection_type        = "VPC_LINK"
  integration_type       = "HTTP_PROXY"
  integration_method     = "ANY"
  integration_uri        = var.default_http_listener_arn
  payload_format_version = "1.0"

  lifecycle {
    precondition {
      condition     = var.vpc_link_id != null && var.vpc_link_id != ""
      error_message = "vpc_link_id must be set in the shared API stack before using connection_type = \"vpc_link\"."
    }
  }
}

resource "aws_ecs_service" "service" {
  name            = var.service_name
  cluster         = var.cluster_id
  task_definition = local.selected_task_definition_arn
  desired_count   = var.desired_task_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    assign_public_ip = false
    security_groups = concat(
      [var.ecs_security_group_id],
      var.additional_security_group_ids,
    )
  }

  dynamic "load_balancer" {
    for_each = local.load_balancers
    content {
      target_group_arn = load_balancer.value.target_group_arn
      container_name   = load_balancer.value.container_name
      container_port   = load_balancer.value.container_port
    }
  }

  enable_execute_command = var.local_tunnel ? true : false
  wait_for_steady_state  = var.wait_for_steady_state

  deployment_circuit_breaker {
    enable   = false
    rollback = false
  }

  deployment_controller {
    type = "ECS"
  }
}

resource "aws_appautoscaling_target" "ecs" {
  count = local.enable_scaling ? 1 : 0

  max_capacity       = var.scaling_strategy.max_scaled_task_count
  min_capacity       = var.desired_task_count
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
      resource_label         = "${var.load_balancer_arn_suffix}/${var.target_group_arn_suffix}"
    }

    target_value       = var.scaling_strategy.alb.target_requests_per_task
    scale_in_cooldown  = local.evaluation_periods_alb_in
    scale_out_cooldown = local.evaluation_periods_alb_out
  }
}
