# `task_worker`

Concrete ECS worker task wrapper.

## Owns

- worker ECS task definition via `_shared/task`
- ECS worker queue via `_shared/sqs`

## Key behavior

- runs `python -u app.py`
- publishes worker task revisions for ECS deploys
- uses the shared ECR repository named by `ecr_repository_name`
- injects its own queue URL into the container via `AWS_SQS_QUEUE_URL`
- defaults `local_tunnel` and `xray_enabled` to `false` unless explicitly enabled

## Key outputs

- `task_definition_arn`
- `service_name`
- `sqs_queue_name`
- `sqs_queue_url`
- log group name

This module is the image-driven deployment unit for the ECS worker and owns the ECS worker queue directly so queue creation follows the task stack lifecycle.
