# `_shared/service`

Shared ECS service module.

This module keeps its own `versions.tf` so it can be lifted into another repo without depending on this repo's Terragrunt-generated provider constraints.

## Owns

- ECS service
- optional bootstrap task used for first infra deploys
- service-level ALB target group and listener rule for sub-path services
- API Gateway VPC link routing for HTTP services
- ECS CodeDeploy app and deployment group for load-balanced ECS services
- service autoscaling policies and alarms

## Does Not Own

- ECS task-definition content
- shared cluster creation
- shared ALB or VPC link creation
- caller-specific deploy ordering outside the service rollout itself

## Inputs That Change Behavior

- `task_definition_arn`
- `connection_type`
- optional `authorization_type` and `authorizer_id` for protected API Gateway routes
- `deployment_strategy`
- `bootstrap`
- `ecr_repository_name`
- `codedeploy_alarm_names`
- `desired_task_count`
- `scaling_strategy`
- `subnet_ids`
- `assign_public_ip`
- optional `dedicated_listener_port`

Subpath services match both `/<root_path>` and `/<root_path>/*`.
If `dedicated_listener_port` is set, the service gets its own ALB listener and uses that listener for API Gateway integration and ECS CodeDeploy traffic routing.
When `connection_type = "vpc_link"`, the module can also attach a shared API Gateway JWT authorizer to both the exact and proxy routes.

## Subnet Selection

By default, callers should pass private `subnet_ids` with `assign_public_ip = false`.
Services that need direct public internet egress without a NAT gateway or service-specific VPC endpoints can pass public `subnet_ids` and set `assign_public_ip = true`.

These inputs change the task ENI placement only. They do not make the service publicly reachable unless the attached security groups and routing resources also allow inbound traffic.
For `connection_type = "vpc_link"`, the public request path remains API Gateway to VPC Link to the internal ALB to the task's private IP; `assign_public_ip = true` only changes the task's outbound internet path.
Callers must provide non-empty `subnet_ids`.

## Bootstrap behavior

Bootstrap ECS services resolve the shared placeholder image from the ECR repository named by `ecr_repository_name` using the stable `bootstrap` tag.
That placeholder image is expected to be a stable shared tag, so infra applies can reuse the same bootstrap task definition input instead of churning a new placeholder image reference on every release.
Bootstrap and real task deploys use the same app health path, such as `/health` or `/<root_path>/health`, so target group health checks do not need to change during the transition from bootstrap to the deployed task.

## Decision Rules

Use [deployment strategies](docs/deployment-strategies.md) when choosing `rolling`, `all_at_once`, `canary`, `linear`, or `blue_green`.

## Connection Types

Use [connection types](docs/connection-types.md) when deciding between `internal`, `internal_dns`, and `vpc_link`.

## Feasibility Constraints

- ECS CodeDeploy requires a load-balanced service shape in this repo
- in practice that means `connection_type` must be `internal_dns` or `vpc_link` for CodeDeploy-backed ECS deploys
- in this repo, subpath ECS services need a dedicated ALB listener if they are meant to use CodeDeploy blue/green
- if `connection_type = "internal"`, prefer `rolling`
- for internal non-load-balanced services, the deploy workflow falls back to native ECS rolling updates

## Scaling Patterns

Use [scaling patterns](docs/scaling-patterns.md) for fixed task count, CPU, SQS, and ALB request examples.

## CI / Deploy Expectations

Infrastructure applies create the stable service shape and deploy workflows own real task rollouts.

Read [rollout and drift](docs/rollout-and-drift.md) for CI deploy expectations, rollback alarms, and ignored-drift ownership.
