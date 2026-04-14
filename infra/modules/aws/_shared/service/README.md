# `_shared/service`

Shared ECS service module.

## Owns

- ECS service
- optional bootstrap task used for first infra deploys
- service-level ALB target group and listener rule for sub-path services
- API Gateway VPC link routing for HTTP services
- ECS CodeDeploy app and deployment group for load-balanced ECS services
- service autoscaling policies and alarms

## Key inputs

- `task_definition_arn`
- `connection_type`
- `deployment_strategy`
- `bootstrap`
- `bootstrap_image_uri`
- `codedeploy_alarm_names`
- optional `dedicated_listener_port`

Subpath services match both `/<root_path>` and `/<root_path>/*`.
If `dedicated_listener_port` is set, the service gets its own ALB listener and uses that listener for API Gateway integration and ECS CodeDeploy traffic routing.

## Bootstrap behavior

Bootstrap ECS services use the shared placeholder image.
Bootstrap health checks use `/`.
Real task deploys use the normal app health path, such as `/health` or `/<root_path>/health`.

## Deployment strategies

- `all_at_once`
- `canary`
- `linear`
- `blue_green`

These map to ECS CodeDeploy deployment configs for load-balanced services.
For internal non-load-balanced services, the deploy workflow falls back to native ECS rolling updates.

## Drift ownership

The ECS service ignores:

- `task_definition`
- `load_balancer`

Reason:

- deploy workflows own the live revision
- infra owns the stable service shape
- CodeDeploy ECS services reject `load_balancer` updates via `UpdateService`
