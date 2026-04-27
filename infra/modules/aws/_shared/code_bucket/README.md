# `_shared/code_bucket`

Shared S3 bucket for deployable artifacts.

## Owns

- Lambda zip storage
- frontend bundle storage
- ECS AppSpec storage for CodeDeploy
- Terragrunt saved plan artifacts under the `terragrunt_plan/` prefix

## Inputs That Change Behavior

- `code_artifact_expiration_days`
- `infra_plan_artifact_expiration_days`

## Decision Rules

- `dev` keeps its own code bucket and stores saved Terragrunt plans there
- non-`dev` environments reuse the shared `ci` code bucket for both release artifacts and saved Terragrunt plans
- lifecycle retention is prefix-scoped: code artifact cleanup applies to `lambdas/`, `frontend/`, and `appspec/`, while saved plan cleanup applies only to `terragrunt_plan/`

## Key outputs

- artifact bucket name

Used by build, build-get, and deploy workflows.
