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

resource "aws_apigatewayv2_route" "block_exact" {
  count = local.vpc_link_count

  api_id    = var.api_id
  route_key = local.exact_route_key

  target = "integrations/${aws_apigatewayv2_integration.block[0].id}"
}

resource "aws_apigatewayv2_route" "block_proxy" {
  count = local.vpc_link_count

  api_id    = var.api_id
  route_key = local.proxy_route_key

  target = "integrations/${aws_apigatewayv2_integration.block[0].id}"
}

resource "aws_apigatewayv2_integration" "block" {
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
