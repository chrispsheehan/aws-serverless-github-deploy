# `task_worker`

Concrete ECS worker task wrapper.

## Owns

- worker ECS task definition via `_shared/task`

## Key behavior

- runs `python -u consumer/app.py`
- publishes worker task revisions for ECS deploys
- uses the shared ECR repository named by `ecr_repository_name`

## Key outputs

- `task_definition_arn`
- `service_name`
- log group name

This module is the image-driven deployment unit for the ECS worker.
