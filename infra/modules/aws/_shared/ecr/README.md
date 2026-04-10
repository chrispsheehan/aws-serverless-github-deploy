# `_shared/ecr`

Shared ECR repository module.

## Owns

- the repository used for ECS images
- repository lifecycle settings

## Key outputs

- `repository_url`

Used by image build, bootstrap image mirroring, and ECS deploy workflows.
