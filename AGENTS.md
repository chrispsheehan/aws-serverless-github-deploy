# Repo Instructions

## Documentation

Update documentation in the same change:

- update the repo root `README.md` for cross-cutting behavior changes
- update affected module `README.md` files under `infra/modules/**` for module contract or responsibility changes

## CI OIDC Scope

- treat `infra/live/ci/aws/oidc/terragrunt.hcl` as intentionally narrow
- the CI OIDC role is for artifact management only: shared code bucket access, current IAM interactions required by CI, and ECR image publishing
- do not broaden the CI role to match the shared `allowed_role_actions` set unless the user explicitly asks for that contract change
- if a task needs deploy permissions, call out that this fails the current CI-role scope and document the exact additional AWS actions or services required

## Deployment Guide

Choose deployment modes that match the runtime shape.

### Lambda

- `all_at_once`
  Use for background jobs and low-risk changes where fastest rollout is preferred.
- `canary`
  Use for request-serving Lambdas such as APIs where a partial rollout and automatic rollback are valuable.
- `linear`
  Use for user-facing or higher-risk Lambdas when you want a steadier rollout than canary.

### ECS

- `rolling`
  Use for ECS services that are not load-balanced in this repo's model, such as internal workers without `internal_dns` or `vpc_link`.
- `all_at_once`
  Use for load-balanced ECS services when you want CodeDeploy but do not need gradual traffic shifting.
- `canary`
  Use for load-balanced ECS services where you want partial traffic shifting before full promotion.
- `linear`
  Use for load-balanced ECS services where you want a gradual, repeated traffic shift.
- `blue_green`
  Treat as an alias of ECS CodeDeploy all-at-once semantics unless and until the repo differentiates it further.

### ECS Constraints

- ECS CodeDeploy requires a load-balanced service shape in this repo.
- In practice that means `connection_type` must be `internal_dns` or `vpc_link` for CodeDeploy-backed ECS deploys.
- If `connection_type = "internal"`, prefer `rolling`.

## Feasibility Check

Before implementing deployment-related changes, check that the requested combination is feasible in the current repo shape.

### What To Check

- runtime type: Lambda or ECS
- deployment mode: `rolling`, `all_at_once`, `canary`, `linear`, or `blue_green`
- connection type for ECS: `internal`, `internal_dns`, or `vpc_link`
- whether the service is load-balanced
- whether the required infra resources already exist, such as:
  - CodeDeploy app and deployment group
  - target groups and listeners
  - VPC link
  - alarm inputs

### Expected Behavior

- If the combination is valid, proceed with implementation.
- If the combination is invalid or incomplete, say so clearly and explain the missing requirement.
- If a requested combination is not feasible in the current repo shape, explicitly state that it fails the feasibility check and say what would need to change to make it feasible.
- Prefer the smallest viable change that matches the requested behavior.

## CI Dependency Safety

When changing CI workflows or Terraform module dependencies, check dependency behavior across the full lifecycle, not just the happy path.

- check apply, deploy, and destroy behavior
- when a workflow calls a reusable workflow, compare the caller `with:` block against the callee `workflow_call.inputs` block before editing anything else
- do that check for every caller of the reusable workflow, not just the file you started in
- treat optional inputs as part of the contract too; verify that each caller is intentionally relying on a default rather than silently omitting an input it actually needs
- if a caller needs data that can be derived inside an existing reusable workflow, prefer adding an explicit reusable-workflow output over adding a new wrapper job just to rediscover the same data
- `infra_releases.yml` is release-time artifact preparation for shared CI resources; do not add it to prod deploy wrappers unless the user explicitly wants deploy-time artifact creation there
- for `*_code` deploy wrappers, check that the dispatch inputs actually cover every runtime being deployed; if ECS deploys are included, the wrapper must expose or deliberately derive an `ecs_version`
- when the same setup or lookup pattern appears in multiple workflows, suggest extracting it into a shared reusable workflow or shared `just` recipe instead of repeating it
- check workflow dependency wiring such as `needs`, job outputs, matrix values, and reused workflow inputs
- watch for `data.terraform_remote_state` dependencies that can fail if another stack has not been created yet or has already been destroyed
- check required Terraform input variables on destroy paths as well as apply paths; destroy can still fail before resource deletion if required vars are unset
- make sure every referenced `needs.<job>.outputs.*` value is actually in scope for that job
- make sure matrix values match the expected naming contract for the workflow, module, or path being used
- for `*_infra` deploy wrappers, verify the infra workflow receives the directory-based infra matrices it needs, while deploy workflows receive the artifact-based matrices and image URIs they need
- for prod wrappers in this repo, remember that shared artifact resources come from `ci`, while deploy target resources are still in `prod`
- prefer making modules tolerant of unnecessary upstream state dependencies where possible
- do not change CI ordering blindly; first check whether the real issue is an avoidable cross-stack dependency
