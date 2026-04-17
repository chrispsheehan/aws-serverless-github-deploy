# `_shared/service`

Shared ECS service module.

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
- `bootstrap_image_uri`
- `codedeploy_alarm_names`
- `desired_task_count`
- `scaling_strategy`
- optional `dedicated_listener_port`

Subpath services match both `/<root_path>` and `/<root_path>/*`.
If `dedicated_listener_port` is set, the service gets its own ALB listener and uses that listener for API Gateway integration and ECS CodeDeploy traffic routing.
When `connection_type = "vpc_link"`, the module can also attach a shared API Gateway JWT authorizer to both the exact and proxy routes.

## Bootstrap behavior

Bootstrap ECS services use the shared placeholder image.
Bootstrap health checks use `/`.
Real task deploys use the normal app health path, such as `/health` or `/<root_path>/health`.

## Decision Rules

Choose deployment strategy based on connection type and whether the service is load-balanced in this repo's model.

### `rolling`

- use for ECS services that are not load-balanced in this repo's model, such as internal workers without `internal_dns` or `vpc_link`
- this uses native ECS rolling updates rather than ECS CodeDeploy

### `all_at_once`

- use for load-balanced ECS services when you want CodeDeploy but do not need gradual traffic shifting

```hcl
deployment_strategy = "all_at_once"
```

### `canary`

- use for load-balanced ECS services where you want partial traffic shifting before full promotion

```hcl
deployment_strategy = "canary"
```

### `linear`

- use for load-balanced ECS services where you want a gradual, repeated traffic shift

```hcl
deployment_strategy = "linear"
```

### `blue_green`

- use when you want explicit blue/green intent in the service configuration
- in the current repo shape this maps to the ECS CodeDeploy all-at-once traffic switch

```hcl
deployment_strategy = "blue_green"
```

## Connection Types

### `internal`

- use for internal services without API Gateway or shared-ALB traffic switching
- prefer `rolling`
- this shape is not compatible with this repo's ECS CodeDeploy path

### `internal_dns`

- use for load-balanced internal services that should be addressable through the shared internal ALB and DNS path
- supports ECS CodeDeploy in this repo

### `vpc_link`

- use for HTTP services exposed through the shared API Gateway via VPC link
- supports ECS CodeDeploy in this repo
- if JWT auth is enabled, the shared API Gateway authorizer is attached in this service shape

## Feasibility Constraints

- ECS CodeDeploy requires a load-balanced service shape in this repo
- in practice that means `connection_type` must be `internal_dns` or `vpc_link` for CodeDeploy-backed ECS deploys
- in this repo, subpath ECS services need a dedicated ALB listener if they are meant to use CodeDeploy blue/green
- if `connection_type = "internal"`, prefer `rolling`
- for internal non-load-balanced services, the deploy workflow falls back to native ECS rolling updates

## Scaling Patterns

Use `desired_task_count` as the steady-state baseline and `scaling_strategy` when you want autoscaling above that baseline.

### Fixed task count

- use for predictable or low-volume services where a fixed number of tasks is enough
- leave `scaling_strategy = {}`

### CPU scaling

- use when task CPU is the best leading signal for scale pressure
- best fit for internal workers or APIs whose load correlates with compute saturation

### SQS scaling

- use for queue-driven workers
- scale decisions are based on the named queue's visible-message count

### ALB request scaling

- use for load-balanced HTTP services
- scale decisions are based on target requests per task behind the ALB

## CI / Deploy Expectations

- infrastructure applies create the stable service shape and any CodeDeploy wiring needed for load-balanced services
- deploy workflows register and promote real `task_*` revisions
- the deployment workflow applies the new task revision, uses CodeDeploy for load-balanced services, and uses native rolling deploys for internal services
- the shared module accepts `codedeploy_alarm_names` for automatic rollback

## Drift / Ownership Rules

The ECS service ignores:

- `task_definition`
- `load_balancer`
- dedicated-listener `default_action`

Reason:

- deploy workflows own the live revision
- infra owns the stable service shape
- CodeDeploy ECS services reject `load_balancer` updates via `UpdateService`
- CodeDeploy also owns the live target-group switch on dedicated listeners
