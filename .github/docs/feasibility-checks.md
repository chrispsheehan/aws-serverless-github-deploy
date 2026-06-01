# Feasibility Checks

Run these checks on every CI, workflow, or deploy-contract change.

## Reusable Workflow Contracts

- Compare every caller `with:` block against the callee `workflow_call.inputs`.
- Compare expected outputs against actual `jobs.<job>.outputs.*`.
- Verify optional inputs are intentionally omitted, not accidentally missing.
- Confirm every `needs.<job>.outputs.*` reference is in scope.
- Confirm matrix values still match naming contracts expected by workflows and modules.
- Do not change CI ordering blindly; first check whether the real issue is avoidable cross-stack coupling.

## Saved Plans

- `apply_plan` jobs must download matching per-stack artifacts into the live stack directory before invoking Terragrunt.
- `terragrunt.plan.meta.json` must exist for apply-from-plan.
- `apply_plan` must fail if metadata says `contains_mocked_outputs: true`.
- When live Terragrunt dependencies use mocks, default to `mock_outputs_merge_strategy_with_state = "shallow"`.
- If cross-run apply should not require re-entered versions or recomputed artifact resolution, store inputs and resolved reusable-workflow outputs in metadata during plan.

## Repo-Local Actions And Justfiles

- Both repo-local composite actions, `./.github/actions/just` and `./.github/actions/terragrunt`, assume AWS credentials are already configured in the job when they need AWS access.
- When using `./.github/actions/just`, check whether the caller needs the repo-root `justfile` or an explicit `justfile_path`.
- If a deploy step passes `APP_SPEC_FILE`, keep it aligned with shared AppSpec templates under `config/deploy/`.
- Keep split `just` ownership clear:
  - repo-root `justfile` for local/developer commands
  - `justfile.ci` for read-only CI helpers
  - `justfile.deploy` for mutating CI build and deploy steps
  - `justfile.destroy` for explicit teardown and post-destroy cleanup steps

## Runtime Coverage

- If Lambda manifest entries change, confirm each `source_dir` exists, each computed zip basename is unique, and each `stack` path exists for every deployed environment.
- If ECS manifest entries change, confirm each `image` source exists and each `task_stack` / `service_stack` path exists for every deployed environment.
- For `*_code` wrappers, confirm dispatch inputs cover every runtime being deployed.
- If ECS deploys are included, confirm `ecs_version` is exposed or intentionally derived.

## Dependency Safety

- Check apply, deploy, and destroy behavior, not just apply.
- Verify Terragrunt dependencies and downstream consumers still exist and are ordered correctly.
- After HCL, Terraform module, live stack dependency, or infra ordering changes, verify with `just tg-all dev plan`; use individual module plans only as extra debugging.
- Prefer fixing avoidable cross-stack coupling instead of adding workflow serialization.
- Keep `shared_infra.yml` as the pure graph executor and prefer handling metadata creation/recovery in dedicated plan/apply wrappers.

## Infra Versus Code Ownership

- `*_infra` wrappers should stop at infrastructure apply.
- `shared_deploy.yml` owns feature-code rollout.
- Prod wrappers should continue reading shared artifact resources from `ci` while applying deploy targets in `prod`.
- Do not add `shared_infra_releases.yml` to prod deploy wrappers unless the goal is explicitly deploy-time artifact creation.

## ECS-Specific Checks

- If helper code is added under `containers/`, confirm discovery logic does not treat it as a deployable image target.
- If service topology changes, verify `connection_type`, load-balancer shape, listeners, and CodeDeploy wiring still satisfy shared ECS feasibility rules.

## Release And Docker Action Checks

- If `release.yml` uses the local version action, keep configured commit prefixes aligned with team commit conventions.
- If allowed PR title prefixes change, update `pull_request.yml` in the same change.
- Ensure release jobs read plain semver tags from repo history in the same format they create.
- If a repo-local Docker action needs git state, resolve checkout from `GITHUB_WORKSPACE` first or walk up to the nearest `.git` root for local harnesses.
- Before running git commands against a mounted checkout in GitHub Actions, add that path to git `safe.directory`.
- Prefer adding PR validation that executes changed repo-local Docker actions through the real GitHub container path.

## Destroy Checks

- Confirm destroy ordering removes downstream consumers before shared stacks.
- Check required Terraform variables on destroy as well as apply.
- Prefer depending on real downstream consumers rather than serializing unrelated shared stacks.
- When a module creates manual backup artifacts outside Terraform ownership, decide explicitly whether destroy should delete or retain them by environment.
- If destroy relies on a final tagged-resource sweep, keep both scan/count and cleanup in `justfile.destroy`.
- Surface unsupported tagged leftovers as explicit workflow warnings.
- If destroy relies on a final tagged-resource sweep, make sure the deploy OIDC role allows `tag:GetResources`.
