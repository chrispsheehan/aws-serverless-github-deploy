locals {
  load_balancer_sg_name = "${var.project_name}-${var.environment}-alb-sg"
  runtime_sg_name       = "${var.project_name}-${var.environment}-runtime-sg"
}
