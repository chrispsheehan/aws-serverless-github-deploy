# `task_api`

Concrete ECS API task wrapper for the sample API service.

## Owns

- sample ECS API task definition via `_shared/task`

## Key behavior

- runs the `containers/api` image
- publishes API task revisions for ECS deploys
- exposes the service on the `/ecs` root path
- defaults `local_tunnel` and `xray_enabled` to `false` unless explicitly enabled

## Key outputs

- `task_definition_arn`
- `service_name`
- log group name

This module is the image-driven deployment unit for the sample ECS API service.
