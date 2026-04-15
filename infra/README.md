# Infra Glossary

This directory contains the Terraform and Terragrunt layout for the repo.

## Structure

- `infra/root.hcl`
  Shared Terragrunt root config. This is where remote state, generated provider config, shared inputs, and naming conventions are defined.
- `infra/modules/aws`
  Reusable Terraform modules.
- `infra/live/<environment>/aws/<stack>`
  Environment-specific Terragrunt stacks that point at modules in `infra/modules/aws`.

## Environments

- `dev`
  Main development environment. This repo also sets `otel_sampling_percentage = 100` there so ECS tracing is fully sampled while iterating.
- `prod`
  Production environment.
- `ci`
  Shared CI-only infra such as ECR and code bucket where applicable. The `aws/oidc` stack here is intentionally scoped to CI artifact management only, including ECR image publishing, rather than the broader deploy permissions used in `dev` and `prod`.

## How State Is Named

The root Terragrunt file derives state paths from the live stack path:

- bucket: `<account>-<region>-<repo>-tfstate`
- key: `<environment>/<provider>/<module>/terraform.tfstate`

Shared artifact names also follow environment-aware conventions from `infra/root.hcl`:

- shared artifact base: `dev -> ...-dev`, otherwise `...-ci`
- code bucket: `<artifact_base>-code`
- ECS ECR repository: `<artifact_base>-ecs-worker`

So a stack at:

`infra/live/dev/aws/task_worker/terragrunt.hcl`

stores state at:

`dev/aws/task_worker/terraform.tfstate`

## Module Types

- `_shared/*`
  Reusable building blocks such as Lambda, ECS task, ECS service, ECR, SQS, cluster, database, and code bucket.
- concrete modules such as `task_worker`, `service_worker`, `lambda_worker`, `api`
  Thin wrappers that apply repo-specific behavior on top of shared modules.

## Shared Stack Responsibilities

- `network`
  Owns the internal ALB, shared HTTP API Gateway API, VPC link, and VPC endpoints, including the SQS interface endpoint used by private ECS workers.
- `security`
  Owns shared security groups.
- `cluster`
  Owns the ECS cluster.
- `api`
  Owns the Lambda-backed API integration and routes into the shared HTTP API.
- `database`
  Owns the shared Aurora PostgreSQL Serverless v2 database stack and its SSM connection parameters.
- `worker_messaging`
  Owns the shared worker SNS topic plus the Lambda-worker and ECS-worker SQS queues used for fanout.
- `task_*`
  Register ECS task definitions.
- `service_*`
  Own the ECS services and, when applicable, CodeDeploy resources.

Current examples include:

- `database`
  Shared Aurora PostgreSQL Serverless v2 shape for repo-managed relational data stores.
- `worker_messaging`
  Shared worker fanout shape: one SNS topic publishes to two independent worker queues so Lambda and ECS consumers each receive the same event.
- `task_worker` / `service_worker`
  Internal ECS worker service shape, with the ECS worker queue owned by `worker_messaging` and a container health check based on a local worker heartbeat file.
- `task_api` / `service_api`
  ECS API service shape exposed on the shared API Gateway at `/ecs` using `vpc_link` and `blue_green`, backed by a dedicated listener on the shared ALB. Through the frontend distribution it is reached at `/api/ecs/*`, while the Lambda API is reached at `/api/*`.

The ECS task wrappers share common app-level tracing code from `containers/shared`, so enabling `xray_enabled` produces app spans as well as sidecar export wiring.
That `containers/shared` directory is helper code only and is not treated as a deployable ECS image target by the CI directory-discovery recipes.

## Dependency Notes

- many modules use `data.terraform_remote_state` to read outputs from other stacks
- because of that, workflow ordering matters for apply, deploy, and destroy
- on destroy, `network` and `cluster` can tear down in parallel once `service_*`, `task_*`, and `frontend` stacks are gone
- avoid making one runtime depend on another runtime's state ownership unnecessarily; for example, shared worker fanout state is owned by `worker_messaging` rather than by `lambda_worker` or `task_worker`
- some shared infrastructure, such as the landing-zone VPC and tagged private subnets, is discovered with `data` lookups and must already exist

## Deployment Model

- infra workflows create or update infrastructure stacks
- build workflows produce Lambda zips and container images
- `*_infra` wrappers need the inputs required to apply infra safely, such as directory-derived stack matrices and any artifact-derived bootstrap references
- in `prod`, the `*_infra` wrappers read shared artifact resources from `ci` but only apply service and task stacks in `prod`
- deploy workflows:
  - publish Lambda versions and use Lambda CodeDeploy
  - register ECS task revisions
  - then either:
    - use ECS CodeDeploy for load-balanced services
    - or use native ECS rolling updates for internal services

## Naming Conventions

- `task_<name>`
  ECS task-definition stack/module
- `service_<name>`
  ECS service stack/module
- `lambda_<name>` or concrete Lambda stack names
  Lambda stacks

In CI workflows, be careful whether a matrix is carrying:

- logical service names like `worker`
- or concrete stack names like `task_worker` / `service_worker`

That distinction has caused several workflow bugs already.
