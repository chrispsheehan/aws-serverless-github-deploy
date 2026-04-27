# `_shared/code_bucket`

Shared S3 bucket for deployable artifacts.

## Owns

- Lambda zip storage
- frontend bundle storage
- ECS AppSpec storage for CodeDeploy
- Terragrunt saved plan artifacts under the `terragrunt_plan/` prefix

## Inputs That Change Behavior

- `lambda_artifact_dir`
- `frontend_artifact_dir`
- `appspec_artifact_dir`
- `infra_plan_dir`
- `code_artifact_expiration_days`
- `infra_plan_artifact_expiration_days`

## Decision Rules

- `dev` keeps its own code bucket and stores saved Terragrunt plans there
- non-`dev` environments reuse the shared `ci` code bucket for both release artifacts and saved Terragrunt plans
- lifecycle retention is prefix-scoped: code artifact cleanup applies to `lambda_artifact_dir/`, `frontend_artifact_dir/`, and `appspec_artifact_dir/`, while saved plan cleanup applies only to `infra_plan_dir/`

## Key outputs

- artifact bucket name

Used by build, build-get, and deploy workflows.
