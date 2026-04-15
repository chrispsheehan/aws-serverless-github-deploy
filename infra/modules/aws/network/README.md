# `network`

Shared network and routing module.

## Owns

- internal ALB
- default listener and target group
- shared HTTP API Gateway API
- default API stage
- VPC link
- interface VPC endpoints, including SQS for private ECS workers and SSM for private runtimes that read Parameter Store values
- S3 gateway endpoint

## Dependencies

- pre-existing tagged VPC and private subnets discovered with `data` lookups
- shared security groups from `security`

## Key outputs

- `load_balancer_arn`
- ALB listener and target group identifiers
- `internal_invoke_url`
- `api_id`
- `api_invoke_url`
- `api_execution_arn`
- `api_stage_name`
- `vpc_link_id`
