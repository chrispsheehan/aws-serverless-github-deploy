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
- uses autoscaling inputs derived from the shared ECS worker queue owned by `messaging`
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

- expects the live Terragrunt stack to pass the `task_worker` task definition through a `dependency` block
- expects the live Terragrunt stack to pass the shared ECS worker queue name through a `dependency` block to drive autoscaling
- expects the live Terragrunt stack to pass the shared `cluster` and `network` outputs as explicit inputs
- expects the live Terragrunt stack to pass the ECS runtime security group id as an explicit input
- relies on `messaging` owning the queue contract rather than duplicating queue state locally
- for bootstrap-friendly plan and validate flows, prefer Terragrunt dependency mocks in the live stack rather than sibling state reads inside the module

It uses the shared ECS worker queue name exported by `messaging` for service autoscaling.
During bootstrap applies, it uses placeholder values instead of reading task outputs directly so the bootstrap path does not need a pre-existing task state file.

## Inherits Behavior From

- [infra/modules/aws/_shared/service/README.md](_shared/service/README.md) for deployment strategies, connection-type rules, feasibility constraints, and drift ownership
