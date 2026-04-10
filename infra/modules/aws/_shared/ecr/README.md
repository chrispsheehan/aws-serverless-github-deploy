# `_shared/ecr`

Shared ECR repository module.

## Owns

- the repository used for ECS images
- repository lifecycle settings

## Key inputs

- `ecr_repository_name`

## Key outputs

- `repository_url`

Used by image build, bootstrap image mirroring, and ECS deploy workflows.
