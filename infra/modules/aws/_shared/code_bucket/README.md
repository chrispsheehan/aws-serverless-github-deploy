# `_shared/code_bucket`

Shared S3 bucket for deployable artifacts.

## Owns

- Lambda zip storage
- frontend bundle storage
- ECS AppSpec storage for CodeDeploy
- Terragrunt saved plan artifacts under the `terragrunt_plan/` prefix

## Decision Rules

- `dev` keeps its own code bucket and stores saved Terragrunt plans there
- non-`dev` environments reuse the shared `ci` code bucket for both release artifacts and saved Terragrunt plans

## Key outputs

- artifact bucket name

Used by build, build-get, and deploy workflows.
