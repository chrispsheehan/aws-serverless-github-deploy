# `service_worker`

Concrete ECS worker service wrapper.

## Owns

- worker ECS service via `_shared/service`

## Dependencies

- `task_worker` remote state
- `cluster`, `network`, `security`, `api`, and `lambda_worker` remote state

## Key outputs

- `service_name`
- `codedeploy_app_name`
- `codedeploy_deployment_group_name`
- `container_port`

This module wires the worker-specific service onto the shared ECS service behavior.
