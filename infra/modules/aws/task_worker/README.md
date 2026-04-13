# `task_worker`

Concrete ECS worker task wrapper.

## Owns

- worker ECS task definition via `_shared/task`

## Key behavior

- runs `python -u app.py`
- publishes worker task revisions for ECS deploys
- uses the shared ECR repository named by `ecr_repository_name`
- reads from the shared worker SQS queue via `AWS_SQS_QUEUE_URL`
- defaults `local_tunnel` and `xray_enabled` to `false` unless explicitly enabled

## Key outputs

- `task_definition_arn`
- `service_name`
- log group name

This module is the image-driven deployment unit for the ECS worker.
