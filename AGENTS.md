# Repo Instructions

## Documentation

Update documentation in the same change:

- update the repo root `README.md` for cross-cutting behavior changes
- update affected module `README.md` files under `infra/modules/**` for module contract or responsibility changes

## Deployment Guide

Choose deployment modes that match the runtime shape.

### Lambda

- `all_at_once`
  Use for background jobs and low-risk changes where fastest rollout is preferred.
- `canary`
  Use for request-serving Lambdas such as APIs where a partial rollout and automatic rollback are valuable.
- `linear`
  Use for user-facing or higher-risk Lambdas when you want a steadier rollout than canary.

### ECS

- `rolling`
  Use for ECS services that are not load-balanced in this repo's model, such as internal workers without `internal_dns` or `vpc_link`.
- `all_at_once`
  Use for load-balanced ECS services when you want CodeDeploy but do not need gradual traffic shifting.
- `canary`
  Use for load-balanced ECS services where you want partial traffic shifting before full promotion.
- `linear`
  Use for load-balanced ECS services where you want a gradual, repeated traffic shift.
- `blue_green`
  Treat as an alias of ECS CodeDeploy all-at-once semantics unless and until the repo differentiates it further.

### ECS Constraints

- ECS CodeDeploy requires a load-balanced service shape in this repo.
- In practice that means `connection_type` must be `internal_dns` or `vpc_link` for CodeDeploy-backed ECS deploys.
- If `connection_type = "internal"`, prefer `rolling`.

## Feasibility Check

Before implementing deployment-related changes, check that the requested combination is feasible in the current repo shape.

### What To Check

- runtime type: Lambda or ECS
- deployment mode: `rolling`, `all_at_once`, `canary`, `linear`, or `blue_green`
- connection type for ECS: `internal`, `internal_dns`, or `vpc_link`
- whether the service is load-balanced
- whether the required infra resources already exist, such as:
  - CodeDeploy app and deployment group
  - target groups and listeners
  - VPC link
  - alarm inputs

### Expected Behavior

- If the combination is valid, proceed with implementation.
- If the combination is invalid or incomplete, say so clearly and explain the missing requirement.
- If a requested deployment combination is not feasible in the current repo shape, explicitly state that it fails the feasibility check and say what would need to change to make it feasible.
- Prefer the smallest viable change that matches the requested deployment behavior.
