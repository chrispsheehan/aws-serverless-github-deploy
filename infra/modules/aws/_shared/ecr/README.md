# `_shared/ecr`

Shared ECR repository module.

## Owns

- the repository used for ECS images
- repository lifecycle settings
- the stable bootstrap image tag used by bootstrap ECS task definitions

## Key inputs

- `ecr_repository_name`
- `bootstrap_image_source`
- `bootstrap_image_tag`

## Key outputs

- `repository_url`

Used by image build and ECS deploy workflows.

By default the module mirrors `nginx:latest` into the repository as the stable
`:bootstrap` tag using the Docker provider. Terraform records that tag in state,
so later applies reuse the same bootstrap image resource instead of relying on a
separate workflow check/push step.

The Terraform runner must have access to a Docker daemon.
