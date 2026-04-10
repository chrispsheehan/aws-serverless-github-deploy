# `security`

Shared security-group module.

## Owns

- load balancer security group
- ECS service security group
- VPC endpoint security group
- API VPC link security group

## Key outputs

- `load_balancer_sg`
- `ecs_sg`
- `vpc_endpoint_sg`
- `api_vpc_link_sg`

Used by `network`, `api`, and ECS service modules.
