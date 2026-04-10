# `network`

Shared network and routing module.

## Owns

- internal ALB
- default listener and target group
- shared HTTP API Gateway API
- default API stage
- VPC link
- interface VPC endpoints
- S3 gateway endpoint

## Dependencies

- pre-existing tagged VPC and private subnets discovered with `data` lookups
- shared security groups from `security`

## Key outputs

- ALB listener and target group identifiers
- `internal_invoke_url`
- `api_id`
- `api_invoke_url`
- `api_execution_arn`
- `api_stage_name`
- `vpc_link_id`
