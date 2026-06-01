# ECS Rollout And Drift

## CI / Deploy Expectations

- infrastructure applies create the stable service shape and any CodeDeploy wiring needed for load-balanced services
- deploy workflows register and promote real `task_*` revisions
- the deployment workflow applies the new task revision, uses CodeDeploy for load-balanced services, and uses native rolling deploys for internal services
- the shared module accepts `codedeploy_alarm_names` for automatic rollback

## Rollback

Use CloudWatch alarms with `codedeploy_alarm_names` when you want ECS CodeDeploy to roll back a load-balanced service deployment automatically.

```hcl
codedeploy_alarm_names = [
  local.api_5xx_alarm_name
]
```

The alarm resources themselves are owned by the caller. This shared module consumes the alarm names and wires them into the ECS deployment group.

## Drift / Ownership Rules

The ECS service ignores:

- `task_definition`
- `load_balancer`
- dedicated-listener `default_action`

Reason:

- deploy workflows own the live revision
- infra owns the stable service shape
- CodeDeploy ECS services reject `load_balancer` updates via `UpdateService`
- CodeDeploy also owns the live target-group switch on dedicated listeners
