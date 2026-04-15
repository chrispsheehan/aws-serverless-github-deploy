resource "aws_security_group" "load_balancer" {
  name        = local.load_balancer_sg_name
  description = "Security group for the internal application load balancer"
  vpc_id      = data.aws_vpc.this.id
}

resource "aws_security_group" "ecs" {
  name        = local.ecs_sg_name
  description = "Security group for ECS services"
  vpc_id      = data.aws_vpc.this.id
}

resource "aws_security_group" "vpc_endpoint" {
  name        = "${var.project_name}-${var.environment}-vpce-sg"
  description = "Security group for interface VPC endpoints"
  vpc_id      = data.aws_vpc.this.id
}

resource "aws_security_group" "api_vpc_link" {
  name        = "${var.project_name}-${var.environment}-api-vpc-link-sg"
  description = "Security group for API Gateway VPC link ENIs"
  vpc_id      = data.aws_vpc.this.id
}

resource "aws_security_group" "postgres" {
  name        = "${var.project_name}-${var.environment}-postgres-sg"
  description = "Security group for shared PostgreSQL databases"
  vpc_id      = data.aws_vpc.this.id
}

resource "aws_vpc_security_group_ingress_rule" "load_balancer_from_vpc_container_port" {
  security_group_id = aws_security_group.load_balancer.id
  cidr_ipv4         = data.aws_vpc.this.cidr_block
  from_port         = var.container_port
  to_port           = var.container_port
  ip_protocol       = "tcp"
  description       = "Allow VPC traffic to the load balancer application port"
}

resource "aws_vpc_security_group_ingress_rule" "load_balancer_from_vpc_additional_listener_port" {
  security_group_id = aws_security_group.load_balancer.id
  cidr_ipv4         = data.aws_vpc.this.cidr_block
  from_port         = var.additional_listener_port
  to_port           = var.additional_listener_port
  ip_protocol       = "tcp"
  description       = "Allow VPC traffic to the load balancer additional listener port"
}

resource "aws_vpc_security_group_egress_rule" "load_balancer_to_internet" {
  security_group_id = aws_security_group.load_balancer.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  description       = "Allow load balancer outbound traffic"
}

resource "aws_vpc_security_group_ingress_rule" "ecs_from_load_balancer" {
  security_group_id            = aws_security_group.ecs.id
  referenced_security_group_id = aws_security_group.load_balancer.id
  from_port                    = var.container_port
  to_port                      = var.container_port
  ip_protocol                  = "tcp"
  description                  = "Allow load balancer traffic to ECS services"
}

resource "aws_vpc_security_group_egress_rule" "ecs_to_internet" {
  security_group_id = aws_security_group.ecs.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  description       = "Allow ECS outbound traffic"
}

resource "aws_vpc_security_group_ingress_rule" "vpc_endpoint_https_from_vpc" {
  security_group_id = aws_security_group.vpc_endpoint.id
  cidr_ipv4         = data.aws_vpc.this.cidr_block
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  description       = "Allow VPC traffic to interface endpoints over HTTPS"
}

resource "aws_vpc_security_group_egress_rule" "vpc_endpoint_https_to_vpc" {
  security_group_id = aws_security_group.vpc_endpoint.id
  cidr_ipv4         = data.aws_vpc.this.cidr_block
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  description       = "Allow interface endpoints to respond to VPC traffic over HTTPS"
}

resource "aws_vpc_security_group_egress_rule" "api_vpc_link_to_internet" {
  security_group_id = aws_security_group.api_vpc_link.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  description       = "Allow API Gateway VPC link outbound traffic"
}

resource "aws_vpc_security_group_egress_rule" "postgres_to_vpc" {
  security_group_id = aws_security_group.postgres.id
  cidr_ipv4         = data.aws_vpc.this.cidr_block
  ip_protocol       = "-1"
  description       = "Allow PostgreSQL outbound traffic within the VPC"
}

resource "aws_vpc_security_group_ingress_rule" "postgres_from_ecs" {
  security_group_id            = aws_security_group.postgres.id
  referenced_security_group_id = aws_security_group.ecs.id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
  description                  = "Allow PostgreSQL access from ECS services only"
}
