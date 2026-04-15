# `task_worker`

Concrete ECS worker task wrapper.

## Owns

- worker ECS task definition via `_shared/task`

## Key behavior

- runs `python -u app.py`
- publishes worker task revisions for ECS deploys
- uses the shared ECR repository named by `ecr_repository_name`
- injects the shared ECS worker queue URL into the container via `AWS_SQS_QUEUE_URL`
- updates a local heartbeat file as it polls and uses an ECS container health check against that heartbeat
- uses the shared ECS tracing helper so SQS receive/process/delete work emits X-Ray spans when `xray_enabled` is enabled
- defaults `local_tunnel` and `xray_enabled` to `false` unless explicitly enabled

## Key outputs

- `task_definition_arn`
- `service_name`
- `sqs_queue_name`
- `sqs_queue_url`
- log group name

This module is the image-driven deployment unit for the ECS worker. It reads the ECS worker queue from the `worker_messaging` stack so the task definition and service can consume the same fanout event stream as the Lambda worker.
