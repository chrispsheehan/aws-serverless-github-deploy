resource "aws_lb" "this" {
  name               = local.load_balancer_name
  internal           = true
  load_balancer_type = "application"
  security_groups    = [data.terraform_remote_state.security.outputs.load_balancer_sg]
  subnets            = data.aws_subnets.private.ids
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
