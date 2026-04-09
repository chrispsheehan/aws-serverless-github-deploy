output "load_balancer_sg" {
  value = aws_security_group.load_balancer.id
}

output "ecs_sg" {
  value = aws_security_group.ecs.id
}

output "vpc_endpoint_sg" {
  value = aws_security_group.vpc_endpoint.id
}

output "api_vpc_link_sg" {
  value = aws_security_group.api_vpc_link.id
}
