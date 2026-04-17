resource "aws_lb" "this" {
  name               = local.load_balancer_name
  internal           = true
  load_balancer_type = "application"
  security_groups    = [data.terraform_remote_state.security.outputs.load_balancer_sg]
  subnets            = data.aws_subnets.private.ids
}

resource "aws_apigatewayv2_api" "http_api" {
  name          = "${var.project_name}-${var.environment}-http"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_vpc_link" "http_api" {
  name               = "${var.project_name}-${var.environment}-http-vpc-link"
  subnet_ids         = data.aws_subnets.private.ids
  security_group_ids = [data.terraform_remote_state.security.outputs.api_vpc_link_sg]
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.http_api.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_apigatewayv2_authorizer" "cognito_jwt" {
  api_id           = aws_apigatewayv2_api.http_api.id
  name             = "${var.project_name}-${var.environment}-cognito-jwt"
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]

  jwt_configuration {
    audience = [data.terraform_remote_state.cognito.outputs.user_pool_client_id]
    issuer   = data.terraform_remote_state.cognito.outputs.issuer_url
  }
}

resource "aws_vpc_endpoint" "interface_endpoints" {
  for_each = local.interface_endpoints

  vpc_id              = data.aws_vpc.this.id
  service_name        = "com.amazonaws.${var.aws_region}.${each.value}"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [data.terraform_remote_state.security.outputs.vpc_endpoint_sg]
  subnet_ids          = data.aws_subnets.private.ids
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "gateway_s3" {
  vpc_id            = data.aws_vpc.this.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = data.aws_route_tables.private.ids
}

resource "aws_lb_target_group" "default" {
  name        = local.target_group_name
  port        = var.container_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = data.aws_vpc.this.id

  health_check {
    path                = "/health"
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    port                = "traffic-port"
    protocol            = "HTTP"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = var.container_port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.default.arn
  }
}
