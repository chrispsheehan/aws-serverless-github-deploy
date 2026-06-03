# Terraform Index

Compact routing index only. For contracts, read `infra/README.md` and the
owning `infra/modules/aws/**/README.md`. For inputs/outputs/resources, inspect
the selected module's `variables.tf`, `outputs.tf`, and `main.tf`.

## Environments

| Environment | Live path | Role |
| --- | --- | --- |
| `ci` | `infra/live/ci` | Shared CI artifact/bootstrap stacks: `oidc`, `ecr`, `code_bucket`. |
| `dev` | `infra/live/dev` | Full development stack plus protected local artifact scaffolding. |
| `prod` | `infra/live/prod` | Production stack set; artifact references are resolved from CI where applicable. |

## Shared Modules

| Module | Owns | Common Consumers | Read Next |
| --- | --- | --- | --- |
| `_shared/cluster` | ECS cluster | `cluster` stacks, ECS services | `infra/modules/aws/_shared/cluster/README.md` |
| `_shared/code_bucket` | S3 artifact bucket and retention | `code_bucket` stacks, build/deploy workflows | `infra/modules/aws/_shared/code_bucket/README.md` |
| `_shared/database` | Aurora PostgreSQL, SSM parameters | `database` wrapper | `infra/modules/aws/_shared/database/README.md` |
| `_shared/ecr` | ECR repository and lifecycle | `ecr` stacks, ECS builds | `infra/modules/aws/_shared/ecr/README.md` |
| `_shared/lambda` | Lambda, alias, CodeDeploy, logs, IAM, provisioned concurrency | Lambda wrapper modules | `infra/modules/aws/_shared/lambda/README.md` |
| `_shared/oidc` | GitHub OIDC deploy role | `oidc` stacks, workflows | `infra/modules/aws/_shared/oidc/README.md` |
| `_shared/service` | ECS service, routing, CodeDeploy, autoscaling | `service_api`, `service_worker` | `infra/modules/aws/_shared/service/README.md` |
| `_shared/sqs` | SQS queue, DLQ, read/write policies | `messaging` | `infra/modules/aws/_shared/sqs/README.md` |
| `_shared/task` | ECS task definition, task IAM, logs | `task_api`, `task_worker` | `infra/modules/aws/_shared/task/README.md` |

## Concrete Modules

| Module | Owns | Consumed By | Depends On |
| --- | --- | --- | --- |
| `cognito` | User pool, app client, hosted UI, readonly group | `network`, `frontend` | Domain/callback inputs |
| `database` | Repo-specific Aurora wrapper | `migrations`, `task_worker`, `rds_reader_tagger` | `security`, existing VPC/subnets |
| `frontend` | S3/CloudFront/ACM/Route53 frontend hosting | frontend deploy workflow | `network`, `cognito`, hosted zone |
| `lambda_api` | Lambda API routes and worker-topic publish access | Lambda deploy, frontend API users | `network`, `messaging`, code bucket |
| `lambda_worker` | Lambda SQS worker | Lambda deploy | `messaging`, code bucket |
| `messaging` | SNS fanout and Lambda/ECS worker queues | API and worker runtimes | `_shared/sqs` |
| `migrations` | VPC-attached migration Lambda | Lambda deploy after-invoke flow | `security`, `database`, code bucket |
| `network` | HTTP API, ALB, VPC Link, authorizer, VPC endpoints | Lambda API, ECS services, frontend | `security`, `cognito`, existing VPC/subnets |
| `observability` | CloudWatch dashboard | operators | Naming inputs |
| `rds_reader_tagger` | Aurora reader tag-sync Lambda/EventBridge rule | Lambda deploy after-invoke flow | `database`, code bucket |
| `security` | Shared security groups and rules | network, database, ECS, VPC Lambdas | existing VPC |
| `service_api` | ECS API service | ECS deploy workflow | `task_api`, `cluster`, `security`, `network` |
| `service_worker` | ECS worker service | ECS deploy workflow | `task_worker`, `cluster`, `security`, `network`, `messaging` |
| `task_api` | ECS API task definition | `service_api`, ECS deploy workflow | ECR/support image inputs |
| `task_worker` | ECS worker task definition and DB/queue access | `service_worker`, ECS deploy workflow | `messaging`, `database`, ECR/support image inputs |

## Fast Routing

- API route or HTTP API issue: start with `network`, then `lambda_api` or
  `service_api`.
- Lambda deployment issue: start with `_shared/lambda`, the concrete Lambda
  module, and `lambdas/deploy.yml`.
- ECS rollout issue: start with `_shared/task`, `_shared/service`,
  `containers/deploy.yml`, and the matching `task_*` / `service_*` modules.
- Database issue: start with `database`, then `migrations` or `task_worker`.
- Auth/frontend issue: start with `cognito`, `frontend`, and
  `frontend/README.md`.
- Dependency or ordering issue: inspect the relevant live
  `terragrunt.hcl` files and run graph helpers described in
  `infra/docs/terragrunt-graph-helpers.md`.
