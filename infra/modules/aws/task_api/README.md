# `task_api`

Concrete ECS API task wrapper for the sample API service.

## Owns

- sample ECS API task definition via `_shared/task`

## Does Not Own

- ECS service rollout or CodeDeploy behavior
- API Gateway route ownership
- shared cluster, ALB, or VPC link resources

## Inputs That Change Behavior

- runs the `containers/api` image
- publishes API task revisions for ECS deploys
- exposes the service on the `/ecs` root path
- uses the shared ECS tracing helper so HTTP requests emit X-Ray spans when `xray_enabled` is enabled
- defaults `local_tunnel` and `xray_enabled` to `false` unless explicitly enabled

## Outputs Consumers Rely On

- `task_definition_arn`
- `service_name`
- log group name

## Runtime Shape

- ECS HTTP task
- paired with `service_api`
- intended for the `/ecs` API path

## Dependency Notes

- publishes the task definition consumed by `service_api`
- relies on the shared ECR/task conventions used by `_shared/task`

This module is the image-driven deployment unit for the sample ECS API service.
