# `_shared/service`

Shared ECS service module.

## Owns

- ECS service
- optional bootstrap task used for first infra deploys
- service-level ALB target group and listener rule for sub-path services
- API Gateway VPC link routing for HTTP services
- ECS CodeDeploy app and deployment group for load-balanced ECS services
- service autoscaling policies and alarms

## Key inputs

- `task_definition_arn`
- `connection_type`
- `deployment_strategy`
- `bootstrap`
- `bootstrap_image_uri`
- `codedeploy_alarm_names`

## Deployment strategies

- `all_at_once`
- `canary`
- `linear`
- `blue_green`

These map to ECS CodeDeploy deployment configs for load-balanced services.
