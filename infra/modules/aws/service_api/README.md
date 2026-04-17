# `service_api`

Concrete ECS API service wrapper for the sample API service.

## Owns

- sample ECS API service via `_shared/service`
- API Gateway VPC link routing on `/ecs`

## Does Not Own

- ECS task-definition content
- shared HTTP API, ALB, or JWT authorizer creation
- shared deployment-strategy rules from `_shared/service`

## Inputs That Change Behavior

- exposes the ECS API container on the shared HTTP API Gateway using `connection_type = "vpc_link"`
- reuses the shared Cognito-backed JWT authorizer from the `network` stack for `/ecs` routes
- uses `deployment_strategy = "blue_green"`
- uses a dedicated ALB listener on port `8080` so ECS CodeDeploy can own traffic
- defaults `local_tunnel` and `xray_enabled` to `false` unless explicitly enabled

## Outputs Consumers Rely On

- `service_name`
- `cluster_name`
- `codedeploy_app_name`
- `codedeploy_deployment_group_name`
- `container_port`

## Runtime Shape

- ECS HTTP service
- `connection_type = "vpc_link"`
- load-balanced through the shared internal ALB
- reached through CloudFront at `/api/ecs/*`
- reached through API Gateway at `/ecs/*`

## Dependency Notes

- reads `task_api` remote state for the task definition
- reads `cluster`, `network`, and `security` remote state
- depends on the `network` stack owning the shared VPC link, ALB listener path, and JWT authorizer inputs

## Inherits Behavior From

- [infra/modules/aws/_shared/service/README.md](/Users/chrissheehan/git/chrispsheehan/aws-serverless-github-deploy/infra/modules/aws/_shared/service/README.md) for deployment strategies, connection-type rules, feasibility constraints, and drift ownership

This module wires the sample ECS API service into the shared API Gateway and ALB infrastructure.
