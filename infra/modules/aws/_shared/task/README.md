# `_shared/task`

Shared ECS task-definition module.

## Owns

- ECS task definition
- task execution role
- task role
- log groups
- optional debug and OpenTelemetry sidecars

## Key inputs

- `image_uri`
- `ecr_repository_name`
- `debug_image_uri`
- `aws_otel_collector_image_uri`
- `local_tunnel`
- `xray_enabled`
- `command`
- optional `health_check`

In the concrete ECS task wrappers in this repo, `local_tunnel` and `xray_enabled` default to `false` unless the environment explicitly opts in.

## Key outputs

- `task_definition_arn`
- `service_name`
- log group names

Use this for task revision creation. Traffic rollout happens at the service layer.

The ECR repository access policy uses the explicit `ecr_repository_name` input. In this repo, Terragrunt sets a root-level default and environments can override it if the repository naming ever changes.

When `health_check` is set, the module adds an ECS container health check to the main service container.
When `xray_enabled` is true, the module also provides the shared ECS tracing environment needed by the app containers to export spans through the OTEL sidecar to X-Ray.
When `local_tunnel` is true, the debug sidecar inherits the same shared and task-specific environment variables as the main app container so ECS Exec sessions can use the runtime connection settings directly.
