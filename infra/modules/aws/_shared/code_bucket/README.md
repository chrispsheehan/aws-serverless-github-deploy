# `_shared/code_bucket`

Shared S3 bucket for deployable artifacts.

## Owns

- Lambda zip storage
- frontend bundle storage
- ECS AppSpec storage for CodeDeploy

## Inputs That Change Behavior

- `lambda_artifact_dir`
- `frontend_artifact_dir`
- `appspec_artifact_dir`
- `code_artifact_expiration_days`

## Decision Rules

- `dev` keeps its own code bucket for local development artifact workflows
- non-`dev` environments reuse the shared `ci` code bucket for release artifacts
- lifecycle retention is prefix-scoped: code artifact cleanup applies to `lambda_artifact_dir/`, `frontend_artifact_dir/`, and `appspec_artifact_dir/`

## Key outputs

- artifact bucket name

Used by build, build-get, and deploy workflows.
