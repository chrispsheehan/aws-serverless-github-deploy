# `service_api`

Concrete ECS API service wrapper for the blue/green API service.

## Owns

- blue/green ECS API service via `_shared/service`
- API Gateway VPC link routing on `/blue-green-api`

## Dependencies

- `task_api` remote state
- `cluster`, `network`, and `security` remote state

## Key behavior

- exposes the ECS API container on the shared HTTP API Gateway using `connection_type = "vpc_link"`
- uses `deployment_strategy = "blue_green"`
- defaults `local_tunnel` and `xray_enabled` to `false` unless explicitly enabled

## Key outputs

- `service_name`
- `cluster_name`
- `codedeploy_app_name`
- `codedeploy_deployment_group_name`
- `container_port`

This module wires the blue/green ECS API service into the shared API Gateway and ALB infrastructure.
