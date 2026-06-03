# Repository Map

Compact routing only. Use this file to choose where to look next, not to learn
full contracts. For behavior, read the owning README before implementation
files.

## Directory Map

| Path | Purpose | Read Next |
| --- | --- | --- |
| `REPO_INSTRUCTIONS.md` | Authoritative agent operating manual and context router. | Start here for every task. |
| `AGENTS.md`, `CLAUDE.md` | Identical wrappers that route agents to `REPO_INSTRUCTIONS.md`. | Do not diverge them. |
| `README.md` | Human-facing repo overview. | Use after `REPO_INSTRUCTIONS.md` for broad orientation. |
| `docs` | Local setup and supporting docs. | `docs/get-started-locally.md`. |
| `.github/workflows` | CI, release, infra plan/apply, code deploy, and destroy workflows. | Workflow Route Map below, then `.github/docs/README.md`. |
| `.github/docs` | Workflow contracts and workflow-doc router. | Pick the focused doc named by `.github/docs/README.md`. |
| `.github/actions` | Repo-local GitHub Actions. | `.github/docs/repo-local-actions.md`, then the action README. |
| `infra` | Terraform/Terragrunt infrastructure. | Terraform Route Map below, then `infra/README.md`. |
| `infra/live` | Environment-specific Terragrunt stacks. | Affected `terragrunt.hcl` files after identifying the stack. |
| `infra/modules/aws/_shared` | Reusable Terraform building blocks. | Terraform Route Map below, then the shared module README. |
| `infra/modules/aws/<module>` | Repo-specific Terraform modules and wrappers. | Terraform Route Map below, then the module README. |
| `infra/docs` | Infra deployment model and Terragrunt graph helpers. | `deployment-model.md` or `terragrunt-graph-helpers.md`. |
| `lambdas` | Lambda source, shared Lambda helpers, and deploy manifest. | `lambdas/README.md`, `lambdas/deploy.yml`. |
| `containers` | ECS source, shared ECS helpers, and deploy manifest. | `containers/README.md`, `containers/deploy.yml`. |
| `frontend` | Vite frontend app. | `frontend/README.md`. |
| `config/deploy` | Lambda/ECS CodeDeploy AppSpec templates. | `.github/docs/reusable-workflows.md`, deploy justfile recipes. |
| `config/otel` | OpenTelemetry collector config. | ECS task modules and container README. |
| `lib` | Shared Python runtime helpers. | Relevant Lambda/container README. |
| `local` | Local harnesses and emulation config. | Runtime README and local setup docs. |
| `justfile*` | Local, CI, deploy, and destroy command surfaces. | `infra/README.md` or `.github/docs/README.md` depending on recipe ownership. |

## Terraform Route Map

For contracts, read `infra/README.md` and the owning
`infra/modules/aws/**/README.md`. For inputs/outputs/resources, inspect only the
selected module's `variables.tf`, `outputs.tf`, and `main.tf`.

### Environments

| Environment | Live path | Role |
| --- | --- | --- |
| `ci` | `infra/live/ci` | Shared CI artifact/bootstrap stacks: `oidc`, `ecr`, `code_bucket`. |
| `dev` | `infra/live/dev` | Full development stack plus protected local artifact scaffolding. |
| `prod` | `infra/live/prod` | Production stack set; artifact references are resolved from CI where applicable. |

### Shared Modules

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

### Concrete Modules

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

### Terraform Shortcuts

- API route or HTTP API issue: start with `network`, then `lambda_api` or
  `service_api`.
- Lambda deployment issue: start with `_shared/lambda`, the concrete Lambda
  module, and `lambdas/deploy.yml`.
- ECS rollout issue: start with `_shared/task`, `_shared/service`,
  `containers/deploy.yml`, and the matching `task_*` / `service_*` modules.
- Database issue: start with `database`, then `migrations` or `task_worker`.
- Auth/frontend issue: start with `cognito`, `frontend`, and
  `frontend/README.md`.
- Dependency or ordering issue: inspect the relevant live `terragrunt.hcl`
  files and run graph helpers described in
  `infra/docs/terragrunt-graph-helpers.md`.

## Workflow Route Map

For contracts, read `.github/docs/README.md` and the focused doc it routes to.
For exact jobs, permissions, inputs, and outputs, inspect only the selected
workflow YAML.

Common AWS workflows use GitHub OIDC and repo variables `AWS_ACCOUNT_ID`,
`AWS_REGION`, and `PROJECT_NAME`. Do not broaden OIDC scope without reading
`REPO_INSTRUCTIONS.md` and `.github/docs/repo-local-actions.md`.

### Entry Points

| Workflow | Trigger | Mutates AWS? | Purpose | Read Next |
| --- | --- | --- | --- | --- |
| `dev_infra_plan.yml` | manual | No | Plan dev infra waves and save plan artifacts. | `.github/docs/artifacts-and-plans.md` |
| `dev_infra_apply_no_plan.yml` | manual | Yes | Apply dev infra directly from current SHA. | `.github/docs/reusable-workflows.md` |
| `dev_infra_apply_from_plan.yml` | manual | Yes | Apply dev infra from a prior saved plan run. | `.github/docs/artifacts-and-plans.md` |
| `dev_code_deploy.yml` | manual | Yes | Build and deploy current dev Lambda/frontend/ECS code. | `.github/docs/workflow-entrypoints.md` |
| `prod_infra_plan.yml` | manual | No | Plan prod infra from selected infra ref. | `.github/docs/artifacts-and-plans.md` |
| `prod_infra_apply_no_plan.yml` | manual | Yes | Apply prod infra directly from pinned workflow ref. | `.github/docs/reusable-workflows.md` |
| `prod_infra_apply_from_plan.yml` | manual | Yes | Apply prod infra from a prior saved plan run. | `.github/docs/artifacts-and-plans.md` |
| `prod_code_deploy.yml` | manual | Yes | Resolve released artifacts from CI and deploy to prod. | `.github/docs/workflow-entrypoints.md` |
| `destroy.yml` | manual | Yes | Destroy selected environment in reverse dependency waves. | `.github/docs/destroy.md` |

### Validation And Release

| Workflow | Trigger | Mutates AWS? | Purpose | Read Next |
| --- | --- | --- | --- | --- |
| `pull_request.yml` | PR/manual | No | Validate PR title, wrapper sync, formatting/linting, manifests, changed runtime builds. | `.github/docs/reusable-workflows.md` |
| `release.yml` | push to `main`/manual | Yes | Create release tag, prepare CI artifacts, build artifacts, publish release. | `.github/docs/reusable-workflows.md` |

### Reusable Workflows

| Workflow | Mutates AWS? | Purpose | Primary Callers |
| --- | --- | --- | --- |
| `shared_build.yml` | Yes | Build/publish Lambda, frontend, and ECS artifacts. | `dev_code_deploy.yml`, `release.yml` |
| `shared_build_get.yml` | No | Resolve existing artifact locations and versions. | `prod_code_deploy.yml` |
| `shared_deploy.yml` | Yes | Publish Lambda versions, frontend assets, ECS task revisions, and service rollouts. | dev/prod code deploy |
| `shared_directories_get.yml` | No | Discover repo-local Docker action directories. | `pull_request.yml` |
| `shared_get_modules.yml` | No | Generate Terragrunt dependency waves. | infra plan/apply/destroy wrappers |
| `shared_infra_plan.yml` | No | Plan infra waves and upload saved plan metadata/artifacts. | dev/prod plan |
| `shared_infra_apply_no_plan.yml` | Yes | Apply infra waves directly. | dev/prod apply-no-plan |
| `shared_infra_apply_from_plan.yml` | Yes | Recover saved plan metadata/artifacts and run `apply_plan`. | dev/prod apply-from-plan |
| `shared_infra_releases.yml` | Yes | Prepare/read CI artifact infra such as ECR and code bucket. | `release.yml` |

### Workflow Shortcuts

- Workflow entry-point behavior: `.github/docs/workflow-entrypoints.md`
- Shared workflow contracts: `.github/docs/reusable-workflows.md`
- Saved plans or apply-from-plan: `.github/docs/artifacts-and-plans.md`
- Matrix/discovery changes: `.github/docs/discovery-and-matrices.md`
- Repo-local action behavior: `.github/docs/repo-local-actions.md`
- Destroy behavior: `.github/docs/destroy.md`
- Feasibility review before workflow edits: `.github/docs/feasibility-checks.md`

## Routing Shortcuts

- Terraform/module work: Terraform Route Map above, then the owning module
  README and targeted source files.
- Workflow work: Workflow Route Map above, then `.github/docs/README.md` and
  the focused workflow doc.
- Runtime work: the runtime README first, then matching manifest and source.
- Cross-cutting deploy work: `AI_CONTEXT.md`, `infra/docs/deployment-model.md`,
  this map, and the owning contract READMEs.
