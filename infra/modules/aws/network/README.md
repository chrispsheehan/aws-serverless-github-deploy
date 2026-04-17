# `network`

Shared network and routing module.

## Owns

- internal ALB
- default listener and target group
- shared HTTP API Gateway API
- default API stage
- shared HTTP API JWT authorizer backed by Cognito
- VPC link
- interface VPC endpoints, including SQS for private ECS workers, SSM for private runtimes that read Parameter Store values, and Secrets Manager for private runtimes that read the shared database credentials object
- S3 gateway endpoint

## Dependencies

- pre-existing tagged VPC and private subnets discovered with `data` lookups
- shared security groups from `security`
- `cognito` remote state for the shared JWT issuer and audience

## Key outputs

- `load_balancer_arn`
- ALB listener and target group identifiers
- `internal_invoke_url`
- `api_id`
- `api_invoke_url`
- `api_execution_arn`
- `api_stage_name`
- `vpc_link_id`
- `http_api_authorizer_id`
