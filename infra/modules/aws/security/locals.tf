locals {
  load_balancer_sg_name = "${var.project_name}-${var.environment}-alb-sg"
  ecs_sg_name           = "${var.project_name}-${var.environment}-ecs-sg"
}
