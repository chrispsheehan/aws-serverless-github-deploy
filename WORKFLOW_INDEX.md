# Workflow Index

Compact routing index only. For contracts, read `.github/docs/README.md` and
the focused doc it routes to. For exact jobs, permissions, inputs, and outputs,
inspect the selected workflow YAML.

Common AWS workflows use GitHub OIDC and repo variables `AWS_ACCOUNT_ID`,
`AWS_REGION`, and `PROJECT_NAME`. Do not broaden OIDC scope without reading
`REPO_INSTRUCTIONS.md` and `.github/docs/repo-local-actions.md`.

## Entry Points

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

## Validation And Release

| Workflow | Trigger | Mutates AWS? | Purpose | Read Next |
| --- | --- | --- | --- | --- |
| `pull_request.yml` | PR/manual | No | Validate PR title, wrapper sync, formatting/linting, manifests, changed runtime builds. | `.github/docs/reusable-workflows.md` |
| `release.yml` | push to `main`/manual | Yes | Create release tag, prepare CI artifacts, build artifacts, publish release. | `.github/docs/reusable-workflows.md` |

## Reusable Workflows

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

## Fast Routing

- Workflow entry-point behavior: `.github/docs/workflow-entrypoints.md`
- Shared workflow contracts: `.github/docs/reusable-workflows.md`
- Saved plans or apply-from-plan: `.github/docs/artifacts-and-plans.md`
- Matrix/discovery changes: `.github/docs/discovery-and-matrices.md`
- Repo-local action behavior: `.github/docs/repo-local-actions.md`
- Destroy behavior: `.github/docs/destroy.md`
- Feasibility review before workflow edits: `.github/docs/feasibility-checks.md`
