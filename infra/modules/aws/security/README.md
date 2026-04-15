# `security`

Shared security-group module.

## Owns

- load balancer security group
- ECS service security group
- VPC endpoint security group
- API VPC link security group
- PostgreSQL database security group

## Key outputs

- `load_balancer_sg`
- `ecs_sg`
- `vpc_endpoint_sg`
- `api_vpc_link_sg`
- `postgres_sg`

Used by `network`, `api`, and ECS service modules.

Rules are defined with standalone `aws_vpc_security_group_ingress_rule` and `aws_vpc_security_group_egress_rule` resources rather than inline security-group blocks.

The load balancer security group allows the main container port and the additional internal listener port from inside the VPC, and permits outbound traffic.
The ECS security group allows only load-balancer traffic on the container port, and permits outbound traffic.
The VPC endpoint security group allows HTTPS traffic to and from the VPC only.
The API VPC link security group permits outbound traffic.
The PostgreSQL security group is intentionally locked down to the shared ECS security group only. Lambda is not included until Lambda VPC access is added.
