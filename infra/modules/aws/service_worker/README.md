# `service_worker`

Concrete ECS worker service wrapper.

## Owns

- worker ECS service via `_shared/service`

## Does Not Own

- ECS task-definition content
- shared worker queue ownership
- shared deployment-strategy rules from `_shared/service`

## Inputs That Change Behavior

- uses the worker task revision exported by `task_worker`
- uses autoscaling inputs derived from the shared ECS worker queue owned by `worker_messaging`
- uses placeholder values during bootstrap applies so the first service apply does not require pre-existing task state

## Outputs Consumers Rely On

- `service_name`
- `cluster_name`
- `codedeploy_app_name`
- `codedeploy_deployment_group_name`
- `container_port`

## Runtime Shape

- ECS worker service
- internal service shape
- no API Gateway route ownership in this wrapper
- expected to prefer the shared module's `rolling` path for non-load-balanced worker deployments

## Dependency Notes

- reads `task_worker` remote state
- reads `worker_messaging` remote state
- reads `cluster`, `network`, and `security` remote state
- relies on `worker_messaging` owning the queue contract rather than duplicating queue state locally

It uses the shared ECS worker queue name exported by `worker_messaging` for service autoscaling.
During bootstrap applies, it uses placeholder values instead of reading task outputs directly so the bootstrap path does not need a pre-existing task state file.

## Inherits Behavior From

- [infra/modules/aws/_shared/service/README.md](/Users/chrissheehan/git/chrispsheehan/aws-serverless-github-deploy/infra/modules/aws/_shared/service/README.md) for deployment strategies, connection-type rules, feasibility constraints, and drift ownership
