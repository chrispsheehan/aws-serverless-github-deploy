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

## Bootstrap behavior

Bootstrap ECS services use the shared bootstrap image, which is a generic placeholder image rather than the real app container.

Because of that, bootstrap target groups health-check `/` instead of the app-specific health endpoint. Once the real task definition is deployed, the normal service health path applies again, such as `/health` or `/<root_path>/health`.

## Deployment strategies

- `all_at_once`
- `canary`
- `linear`
- `blue_green`

These map to ECS CodeDeploy deployment configs for load-balanced services.
For internal non-load-balanced services, the deploy workflow falls back to native ECS rolling updates.

## Drift ownership

The ECS service ignores changes to `task_definition`.

That is intentional:

- deploy workflows own the live task revision
- infra applies own the stable service shape

Without that split, a later infra apply would revert a successful rolling or CodeDeploy deployment back to the older task definition stored in Terraform state.
