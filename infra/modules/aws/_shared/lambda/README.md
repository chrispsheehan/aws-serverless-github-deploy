# `_shared/lambda`

Shared Lambda module with versioned deploys through CodeDeploy.

This module keeps its own `versions.tf` so it can be lifted into another repo without depending on this repo's Terragrunt-generated provider constraints.

## Owns

- Lambda function
- alias and published versions
- optional provisioned concurrency
- Lambda CodeDeploy app and deployment group
- bootstrap zip used for initial infra applies

## Does Not Own

- API Gateway routes
- frontend routing or auth behavior
- caller-specific alarms beyond the names passed in
- concrete Lambda business logic

## Inputs That Change Behavior

- `deployment_config`
- `provisioned_config`
- `codedeploy_alarm_names`
- `code_bucket`
- `timeout_seconds`
- optional `vpc_subnet_ids` and `vpc_security_group_ids` when the Lambda must run inside private subnets

When VPC attachment is enabled, the module creates and attaches its own Lambda VPC access policy covering the EC2 network-interface permissions needed for private-subnet execution.

## Outputs Consumers Rely On

- function name and ARN
- alias name and ARN
- log group

## Decision Rules

Choose deployment modes that match the Lambda runtime shape.

### `all_at_once`

- use for background jobs and lower-risk changes where fastest rollout is preferred
- best fit when a temporary full-traffic switch is acceptable

```hcl
deployment_config = {
  strategy = "all_at_once"
}
```

### `canary`

- use for request-serving Lambdas such as APIs where partial rollout and automatic rollback are valuable
- shifts a percentage of traffic first, then promotes to full traffic after the interval

```hcl
deployment_config = {
  strategy         = "canary"
  percentage       = 10
  interval_minutes = 1
}
```

### `linear`

- use for user-facing or higher-risk Lambdas when you want a steadier rollout than canary
- shifts traffic repeatedly by the configured percentage and interval until complete

```hcl
deployment_config = {
  strategy         = "linear"
  percentage       = 10
  interval_minutes = 1
}
```

## Feasibility Constraints

- valid strategies are `all_at_once`, `canary`, and `linear`
- `canary` and `linear` require both `percentage` and `interval_minutes`
- use this module when you want Lambda infrastructure and Lambda rollout behavior managed together through versions and aliases

## CI / Deploy Expectations

- infrastructure applies create the placeholder zip, function, alias, and CodeDeploy resources
- code deploy workflows publish real Lambda versions and move the alias through CodeDeploy
- automatic rollback can be wired through `codedeploy_alarm_names`

## Rollback

Use CloudWatch alarms with `codedeploy_alarm_names` when you want CodeDeploy to roll back a Lambda deployment automatically.

```hcl
codedeploy_alarm_names = [
  local.api_5xx_alarm_name
]
```

The alarm resources themselves are owned by the caller. This shared module consumes the alarm names and wires them into the Lambda deployment group.

## Drift / Ownership Rules

- infra owns the stable Lambda shape, alias, and CodeDeploy wiring
- deploy workflows own the live published version progression

Use this when you want Lambda infra and Lambda rollout behavior managed together.

## Provisioned Concurrency Patterns

Use `provisioned_config` to choose the Lambda warm-capacity shape.

### No provisioned concurrency

- best for background jobs and lower-frequency work where cold-start lag is acceptable

```hcl
provisioned_config = {
  fixed                = 0
  reserved_concurrency = 2
}
```

### Fixed provisioned concurrency

- best for predictable request volume where you want a known warm pool

```hcl
provisioned_config = {
  fixed                = 10
  reserved_concurrency = 50
}
```

### Autoscaled provisioned concurrency

- best for request-serving Lambdas where you want baseline warm capacity and cost control above that baseline

```hcl
provisioned_config = {
  auto_scale = {
    max               = 3
    min               = 1
    trigger_percent   = 70
    cool_down_seconds = 60
  }
}
```
