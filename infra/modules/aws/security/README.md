# `security`

Shared security-group module.

## Owns

- load balancer security group
- shared runtime security group
- VPC endpoint security group
- API VPC link security group
- PostgreSQL database security group

## Key outputs

- `load_balancer_sg`
- `runtime_sg`
- `ecs_sg`
- `vpc_endpoint_sg`
- `api_vpc_link_sg`
- `postgres_sg`

Used by `network`, `lambda_api`, and ECS service modules.

Rules are defined with standalone `aws_vpc_security_group_ingress_rule` and `aws_vpc_security_group_egress_rule` resources rather than inline security-group blocks.

The load balancer security group allows the main container port and the additional internal listener port from inside the VPC, and permits outbound traffic.
The shared runtime security group allows only load-balancer traffic on the container port, and permits outbound traffic.
`ecs_sg` is kept as a compatibility alias for existing ECS consumers, while `runtime_sg` is the preferred generic output for cross-runtime reuse.
The VPC endpoint security group allows HTTPS traffic to and from the VPC only.
The API VPC link security group permits outbound traffic.
The PostgreSQL security group is intentionally locked down to the shared runtime security group only. VPC-attached Lambdas can still use the database by reusing that same shared runtime security group, which is how the `migrations` Lambda is wired.
