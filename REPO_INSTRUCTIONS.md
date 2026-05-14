# Repo Instructions

These instructions apply to the entire repository.

## Keep `AGENTS.md` and `CLAUDE.md` identical

`REPO_INSTRUCTIONS.md` is the shared source of truth for repo guidance.

- `AGENTS.md` and `CLAUDE.md` must remain byte-for-byte identical wrapper files that direct the agent to read `./REPO_INSTRUCTIONS.md`.
- If you change the wrapper text in one file, make the same change in the other file.
- Do not intentionally diverge the contents between those two wrapper files.

## Escalation (Commands That Often Need Real AWS/Network/Docker)

- request escalation for `just tg <env> <module> plan|validate` and `just tg-all <op>`
- request escalation for Docker local-stack debugging (for example `docker compose -f docker-compose.local.yml logs|ps|exec|up|down`)
- prefer asking for escalation up front when the task clearly depends on AWS, remote state, or the local Docker daemon

## Documentation Contract

- keep docs aligned with behavior changes
- entry point: `README.md` (high-level map only)
- workflow contracts: `.github/docs/README.md`
- module contracts: `infra/modules/**/README.md` (shared contracts live under `infra/modules/aws/_shared/**/README.md`)
- runtime behavior: `lambdas/**/README.md` and `containers/**/README.md`

## CI OIDC Scope

- treat `infra/live/ci/aws/oidc/terragrunt.hcl` as intentionally narrow
- the CI OIDC role is for artifact management only: shared code bucket access, current IAM interactions required by CI, and ECR image publishing
- do not broaden the CI role to match the shared `allowed_role_actions` set unless the user explicitly asks for that contract change
- if a task needs deploy permissions, call out that this fails the CI-role scope and name the missing AWS actions/services

## Feasibility + Dependency Checks (When Editing Infra / Workflows)

- verify runtime type (Lambda/ECS), deploy mode, and (for ECS) connection type and load-balancer shape
- verify required infra resources exist (CodeDeploy app/deployment group, listeners/target groups, alarms, VPC link if applicable)
- when changing reusable workflow contracts, compare every caller `with:` block to the callee `workflow_call.inputs`
- check apply/deploy/destroy, and avoid unnecessary `terraform_remote_state` coupling (especially for fast-changing outputs)
- for bootstrap-sensitive or plan-sensitive cross-stack contracts, prefer Terragrunt `dependency` inputs in the live stack and `mock_outputs` for non-mutating commands rather than reading upstream state directly inside Terraform modules
- if CI plan failures are caused by missing upstream state, fix the contract shape first instead of papering over the issue with more direct `terraform_remote_state` reads
- when the same Terragrunt dependency wiring or mocks are needed across environments, centralize that shared config under `infra/live/dependencies/` in a capability-scoped helper such as `network.hcl` and have environment stacks read it rather than duplicating the same blocks in `dev`, `prod`, or `ci`
- keep this approach visible to users as well: when you introduce or expand this pattern, update the top-level `README.md` so the bootstrap-friendly mock strategy is documented outside agent-only instructions
- if you intentionally add a Terraform `data "terraform_remote_state"` block, add a `# remote_state_reason: ...` comment immediately above it explaining why Terragrunt `dependency` plus `mock_outputs` is not practical for that case
- if you intentionally add a Terraform `data "terraform_remote_state"` block, add a `# remote_state_reason: ...` comment immediately above it explaining why Terragrunt `dependency` plus `mock_outputs` is not practical for that case

## Terragrunt Plan Expectation

- when a change touches `*.hcl`, Terraform modules, live Terragrunt stacks, or downstream dependencies that can affect Terraform evaluation or plan output, run the relevant `just tg <env> <module> plan` command before closing the task when feasible
- choose the smallest relevant plan surface rather than defaulting to `run-all`; for example, plan only the affected `dev`, `ci`, or `prod` stack(s)
- when shared modules or remote-state contracts change, consider the downstream consumer stacks too and run plans for the affected dependents, not just the module wrapper you edited
- treat saved plans as apply-intent artifacts, not as general previews: only keep a `plan` you expect to apply, because Terraform reuses the exact planned variable values during `apply_plan`
- be especially careful on first deploys or bootstrap-sensitive stacks that use Terragrunt `mock_outputs` for planability; if a saved plan captured mock values, discard it and create a fresh plan after the upstream real outputs exist
- if a plan is not feasible because credentials, network, permissions, or state access are unavailable, say that explicitly in the final response and name the plan command that should be run manually

## High-Signal Edit Warnings

- before editing `justfile.ci` or `justfile.deploy`, print an explicit terminal warning in commentary (CI/deploy command ownership boundary)
- before editing `infra/modules/aws/_shared/**`, print an explicit terminal warning in commentary (shared-contract blast radius)
