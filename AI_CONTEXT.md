# AI Context

This is an AI-friendly repository summary. It is not authoritative guidance.
Read `REPO_INSTRUCTIONS.md` first, then use this file to decide which existing
contract docs and source files to load next.

## Purpose

This repository is a Terraform/Terragrunt and GitHub Actions template for AWS
application deployments. It manages Lambda, ECS, frontend hosting, auth,
database, messaging, observability, artifact storage, and CI/CD deployment
surfaces.

Primary contracts remain in:

- `REPO_INSTRUCTIONS.md` for agent operating rules
- `README.md` for the human-facing repo entry point
- `infra/README.md` for stack ownership and dependency strategy
- `.github/docs/README.md` for workflow contracts

## Architecture

The repo separates stable infrastructure from feature-code rollout.

- Terragrunt live stacks under `infra/live/<environment>/aws/<stack>` call
  reusable Terraform modules under `infra/modules/aws`.
- Shared modules under `infra/modules/aws/_shared` implement reusable Lambda,
  ECS, SQS, ECR, code bucket, database, OIDC, and cluster building blocks.
- Concrete modules wrap shared modules with repo-specific naming, runtime
  config, API routes, queue wiring, database access, and deploy behavior.
- Runtime source lives outside Terraform in `lambdas`, `containers`, and
  `frontend`.
- Build and deploy workflows derive rollout matrices from
  `lambdas/deploy.yml` and `containers/deploy.yml`.

For detailed deployment semantics, read `infra/docs/deployment-model.md`.

## Deployment Flow

- Infra workflows plan or apply Terragrunt stacks in dependency waves.
- Saved infra plans use one run-level metadata artifact plus one per-stack plan
  artifact.
- Code deploy workflows build or resolve artifacts, publish Lambda versions,
  register ECS task revisions, update services, and publish frontend assets.
- Lambda and ECS CodeDeploy resources are created by infra stacks and consumed
  by deploy workflows.

Read `.github/docs/workflow-entrypoints.md`,
`.github/docs/reusable-workflows.md`, and
`.github/docs/artifacts-and-plans.md` before editing workflow behavior.

## Infrastructure Topology

Core AWS surfaces:

- API Gateway HTTP API with Cognito JWT authorization and VPC Link
- Internal ALB, listeners, target groups, and ECS service routing
- Lambda functions with aliases, CodeDeploy groups, provisioned concurrency,
  SQS triggers, and API Gateway integrations
- ECS cluster, task definitions, services, CodeDeploy groups, and auto scaling
- SNS topic fanout to Lambda-worker and ECS-worker SQS queues
- Aurora PostgreSQL Serverless v2 with SSM connection parameters and Secrets
  Manager credentials
- S3 code/artifact buckets, frontend bucket, CloudFront distribution, ACM cert,
  and Route53 records
- ECR repository with lifecycle policy and bootstrap image support
- CloudWatch logs, dashboards, alarms, EventBridge, IAM roles/policies, VPC
  endpoints, and security groups

Security and network boundaries are summarized in `REPO_MAP.md`; implementation
contracts live in the relevant module READMEs.

## Environment Strategy

- `ci`: shared artifact/bootstrap infrastructure, including CI-scoped OIDC,
  ECR, and code bucket stacks.
- `dev`: full development environment plus local artifact scaffolding. The
  protected `oidc`, `ecr`, and `code_bucket` stacks remain present for local
  workflows and bootstrap support.
- `prod`: deployable production stack set. Production artifact references are
  resolved from CI-owned shared artifact resources.

Environment-specific values live under `infra/live/<env>`. Global values live
in `infra/live/global_vars.hcl`.

## Terraform Layout

- `infra/root.hcl`: shared Terragrunt root config, remote state naming, provider
  generation, and common inputs.
- `infra/live/<env>/aws/<stack>/terragrunt.hcl`: deployable stack wrappers and
  explicit Terragrunt dependency edges.
- `infra/modules/aws/_shared/*`: reusable module primitives.
- `infra/modules/aws/<module>`: repo-specific wrappers or concrete stack
  modules.

Use `REPO_MAP.md#terraform-route-map` for compact module routing, then read the
owning module README before editing a module.

## Workflow Layout

- Environment entry points: `dev_*`, `prod_*`, and `destroy.yml`
- Reusable build/deploy/infra wrappers: `shared_*.yml`
- Validation and release: `pull_request.yml`, `release.yml`
- Repo-local actions: `.github/actions/get-changes`, `just`, and
  `terragrunt`

Use `REPO_MAP.md#workflow-route-map` for compact workflow routing, then read
`.github/docs/README.md` and the focused workflow doc before editing.
