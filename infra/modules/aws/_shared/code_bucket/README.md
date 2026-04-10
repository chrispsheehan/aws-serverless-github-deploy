# `_shared/code_bucket`

Shared S3 bucket for deployable artifacts.

## Owns

- Lambda zip storage
- frontend bundle storage
- ECS AppSpec storage for CodeDeploy

## Key outputs

- artifact bucket name

Used by build, build-get, and deploy workflows.
