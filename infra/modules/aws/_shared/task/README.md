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
- `debug_image_uri`
- `aws_otel_collector_image_uri`
- `local_tunnel`
- `xray_enabled`
- `command`

## Key outputs

- `task_definition_arn`
- `service_name`
- log group names

Use this for task revision creation. Traffic rollout happens at the service layer.

The ECR repository access policy is derived from `image_uri`, so deploy workflows should pass the final image URI rather than relying on repository-name conventions.
