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

## Routing Surface

This module is the shared routing layer for both Lambda-backed and ECS-backed APIs in this repo.

- Lambda routes plug into the shared HTTP API at `/*`
- ECS API routes plug into the shared HTTP API at `/ecs/*`
- the frontend exposes those as `/api/*` for Lambda and `/api/ecs/*` for ECS
- the shared JWT authorizer from this module can be attached to both Lambda and ECS API paths

In the common ECS API shape used here:

- the ECS service uses `connection_type = "vpc_link"`
- the ECS service owns its dedicated listener and routing details
- the ALB itself, the base listener surface, and the VPC link stay here in `network`

## Dependencies

- pre-existing tagged VPC and private subnets discovered with `data` lookups
- shared security groups from `security`
- `cognito` remote state for the shared JWT issuer and audience

## Bootstrap Notes

This module is not bootstrap-independent. It reads multiple outputs from the `security` stack through remote state, including `vpc_endpoint_sg` for the interface VPC endpoints and `api_vpc_link_sg` for the shared API Gateway VPC link.

That means:

- `security` must be applied successfully before `network`
- the `security` state file must contain the current outputs, not just an empty or partially initialized state
- a failed or stale bootstrap of `security` can surface here as an `Unsupported attribute` error when Terraform tries to read `data.terraform_remote_state.security.outputs.*`

If you see an error like:

```text
Error: Unsupported attribute
data.terraform_remote_state.security.outputs is object with no attributes
This object does not have an attribute named "vpc_endpoint_sg".
```

then the problem is usually not the `network` module itself. It means the upstream `security` stack has not produced readable outputs yet. In that case, apply `security` first and confirm its state includes `vpc_endpoint_sg`, `api_vpc_link_sg`, and the other expected outputs before retrying `network`.

## Feasibility Constraints

- this module expects the landing-zone or StackSet VPC and the required private subnets to already exist
- if the VPC or subnet discovery data lookups fail, downstream runtime stacks cannot be applied

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
