# `task_worker`

Concrete ECS worker task wrapper.

## Owns

- worker ECS task definition via `_shared/task`

## Does Not Own

- ECS service rollout or autoscaling behavior
- worker queue ownership
- shared cluster creation

## Inputs That Change Behavior

- runs `python -u app.py`
- publishes worker task revisions for ECS deploys
- uses the shared ECR repository named by `ecr_repository_name`
- injects the shared ECS worker queue URL into the container via `AWS_SQS_QUEUE_URL`
- injects Aurora PostgreSQL connection details and a single Secrets Manager credentials object reference
- updates a local heartbeat file as it polls and uses an ECS container health check against that heartbeat
- uses the shared ECS tracing helper so SQS receive/process/delete work emits X-Ray spans when `xray_enabled` is enabled
- defaults `local_tunnel` and `xray_enabled` to `false` unless explicitly enabled
- when `local_tunnel` is enabled, the debug sidecar can be reached with ECS Exec and inherits the worker runtime database settings for ad hoc `psql` inspection

## Outputs Consumers Rely On

- `task_definition_arn`
- `service_name`
- `sqs_queue_name`
- `sqs_queue_url`
- log group name

## Runtime Shape

- ECS worker task
- paired with `service_worker`
- queue-driven runtime with a heartbeat-file health check instead of an HTTP health endpoint

## Dependency Notes

- expects the live Terragrunt stack to pass queue details from `messaging` through a `dependency` block
- expects the live Terragrunt stack to pass shared `database` connection details as explicit inputs
- publishes the task definition consumed by `service_worker`

This module is the image-driven deployment unit for the ECS worker. It consumes the ECS worker queue contract owned by `messaging` and the shared `database` contract passed in from the live Terragrunt stack so the task definition and service can use the same fanout event stream and Aurora PostgreSQL connection details without the module reading sibling stack state directly.
