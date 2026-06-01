# ECS Deployment Strategies

Choose deployment strategy based on connection type and whether the service is load-balanced in this repo's model.

## `rolling`

- use for ECS services that are not load-balanced in this repo's model, such as internal workers without `internal_dns` or `vpc_link`
- this uses native ECS rolling updates rather than ECS CodeDeploy

## `all_at_once`

- use for load-balanced ECS services when you want CodeDeploy but do not need gradual traffic shifting

```hcl
deployment_strategy = "all_at_once"
```

## `canary`

- use for load-balanced ECS services where you want partial traffic shifting before full promotion

```hcl
deployment_strategy = "canary"
```

## `linear`

- use for load-balanced ECS services where you want a gradual, repeated traffic shift

```hcl
deployment_strategy = "linear"
```

## `blue_green`

- use when you want explicit blue/green intent in the service configuration
- in the current repo shape this maps to the ECS CodeDeploy all-at-once traffic switch

```hcl
deployment_strategy = "blue_green"
```
