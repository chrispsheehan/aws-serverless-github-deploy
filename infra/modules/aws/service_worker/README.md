# `service_worker`

Concrete ECS worker service wrapper.

## Owns

- worker ECS service via `_shared/service`

## Dependencies

- `task_worker` remote state
- `worker_messaging` remote state
- `cluster`, `network`, and `security` remote state

## Key outputs

- `service_name`
- `cluster_name`
- `codedeploy_app_name`
- `codedeploy_deployment_group_name`
- `container_port`

This module wires the worker-specific service onto the shared ECS service behavior.

It uses the shared ECS worker queue name exported by `worker_messaging` for service autoscaling.
During bootstrap applies, it uses placeholder values instead of reading task outputs directly so the bootstrap path does not need a pre-existing task state file.
