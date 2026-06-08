# CI And Workflow Contracts

Use this directory when changing GitHub Actions, repo-local actions, CI helpers, deploy workflows, or workflow-owned `just` behavior.

This README is the router. The contract details live in focused docs so humans and agents can load only the context they need.

## Read Next

| Task | Read |
| --- | --- |
| Find the workflow a user should trigger | [workflow-entrypoints.md](workflow-entrypoints.md) |
| Change reusable build, infra, deploy, or release workflow behavior | [reusable-workflows.md](reusable-workflows.md) |
| Change saved plan, apply-from-plan, artifact naming, or plan metadata behavior | [artifacts-and-plans.md](artifacts-and-plans.md) |
| Change runtime manifests, action discovery, or Terragrunt graph waves | [discovery-and-matrices.md](discovery-and-matrices.md) |
| Change `.github/actions/**`, OIDC role ARN construction, release tagging, or action tests | [repo-local-actions.md](repo-local-actions.md) |
| Change destroy behavior, post-destroy cleanup, or tagged-resource sweeps | [destroy.md](destroy.md) |
| Review any workflow or CI contract change | [feasibility-checks.md](feasibility-checks.md) |

## Workflow Groups

| Group | Workflows |
| --- | --- |
| Release and validation | `release.yml`, `pull_request.yml` |
| Shared artifact prep and build | `shared_infra_releases.yml`, `shared_build.yml`, `shared_build_get.yml` |
| Shared infra and code rollout | `shared_infra_plan.yml`, `shared_infra_apply_no_plan.yml`, `shared_infra_apply_from_plan.yml`, `shared_infra.yml`, `shared_deploy.yml` |
| Discovery | `shared_directories_get.yml`, `shared_get_modules.yml` |
| Environment entry points | `dev_infra_apply_no_plan.yml`, `dev_infra_plan.yml`, `dev_infra_plan_and_apply.yml`, `dev_infra_apply_from_plan.yml`, `dev_code_deploy.yml`, `prod_infra_apply_no_plan.yml`, `prod_infra_plan.yml`, `prod_infra_apply_from_plan.yml`, `prod_code_deploy.yml` |
| Cleanup | `destroy.yml` |

## Repo-Local Actions

- [get-changes](../actions/get-changes/README.md)
- [just](../actions/just/README.md)
- [terragrunt](../actions/terragrunt/README.md)

For action ownership, OIDC ARN construction, and action-specific checks, see [repo-local-actions.md](repo-local-actions.md).

## Fast Paths

For most workflow edits:

1. Start with the task-specific doc above.
2. Check [feasibility-checks.md](feasibility-checks.md) before editing.
3. If the change touches Terragrunt graph edges, saved plans, deploy ordering, or runtime discovery, also read the relevant infra/runtime README named by `REPO_INSTRUCTIONS.md`.

For entry-point behavior, use [workflow-entrypoints.md](workflow-entrypoints.md).

For reusable workflow inputs, outputs, artifacts, and action behavior, use [reusable-workflows.md](reusable-workflows.md), [artifacts-and-plans.md](artifacts-and-plans.md), and [repo-local-actions.md](repo-local-actions.md).

For destroy behavior, use [destroy.md](destroy.md) before editing `destroy.yml` or `justfile.destroy`.
