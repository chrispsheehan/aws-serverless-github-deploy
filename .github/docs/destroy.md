# Destroy Workflow

Use this before editing `destroy.yml`, `justfile.destroy`, or post-destroy cleanup behavior.

## Workflow Contract

`destroy.yml` tears down infrastructure through the same Terragrunt graph contract as plan/apply, but in reverse shared-infra wave order.

- Shares `infra-mutate-<environment>` with mutating apply workflows, so a destroy cannot overlap an apply in the same environment.
- Derives current module waves through `shared_get_modules.yml`.
- Uses filtering inputs to omit `oidc` entirely.
- Omits `code_bucket` and `ecr` unless `allow_cleanup` is enabled.
- Runs `wave_2`, `wave_1`, and `wave_0`.
- Intentionally omits the dedicated `wave_3` destroy stage.
- The only remaining module-specific destroy placeholder vars are required ECS task image inputs for `task_*`.
- Frontend, service, and database stacks rely on Terragrunt dependency mocks instead of workflow-injected destroy placeholders.

## Cleanup

When `allow_cleanup` is enabled:

- the workflow first counts tagged leftovers through `justfile.destroy`
- it prints a warning only when leftovers remain
- it then runs the cleanup recipe
- cleanup deregisters and deletes tagged ECS task-definition revisions
- cleanup force-deletes tagged Secrets Manager secrets
- cleanup validates those resource types against underlying service APIs rather than treating the tagging index as source of truth
- already-removed ECS task-definition revisions or Secrets Manager secrets are successful no-ops so stale tagging API results do not fail cleanup
- unsupported or still-live tagged resources after cleanup are recorded as workflow warnings and step-summary entries rather than failing the whole destroy run

`prod` runs that same path only when `allow_cleanup` is enabled, and the workflow prints a conspicuous warning first.

## Destroy-Path Checks

- Confirm destroy ordering removes downstream consumers before shared stacks.
- Check required Terraform variables on destroy as well as apply.
- Prefer depending on real downstream consumers rather than serializing unrelated shared stacks.
- When a module creates manual backup artifacts outside Terraform ownership, decide explicitly whether destroy should delete or retain them by environment.
- If destroy relies on a final tagged-resource sweep, keep both the scan/count step and cleanup step in `justfile.destroy`.
- Surface unsupported tagged leftovers as explicit workflow warnings so new leak classes remain visible.
- If destroy relies on a final tagged-resource sweep, make sure the deploy OIDC role allows `tag:GetResources`; cleanup uses the Resource Groups Tagging API before service-specific deletions.
