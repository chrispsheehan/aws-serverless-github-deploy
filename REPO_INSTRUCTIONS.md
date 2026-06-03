# Repo Instructions

These instructions apply to the entire repository.

## Repository Scope

- these instructions apply when the session is launched in this repository
- if the user mentions another local repository or folder, treat it as external reference material unless the user explicitly says to move the work there
- do not assume another repository inherits instructions from this repository

## Keep `AGENTS.md` and `CLAUDE.md` identical

`REPO_INSTRUCTIONS.md` is the shared source of truth for repo guidance.

- `AGENTS.md` and `CLAUDE.md` must remain byte-for-byte identical wrapper files that direct the agent to read `./REPO_INSTRUCTIONS.md`.
- If you change the wrapper text in one file, make the same change in the other file.
- Do not intentionally diverge the contents between those two wrapper files.

## Escalation (Commands That Often Need Real AWS/Network/Docker)

- request escalation for `just tg <env> <module> validate` and `just tg-all <env> plan|apply|destroy`
- request escalation for Docker local-stack debugging (for example `docker compose -f docker-compose.local.yml logs|ps|exec|up|down`)
- prefer asking for escalation up front when the task clearly depends on AWS, remote state, or the local Docker daemon

## Documentation Contract

- keep docs aligned with behavior changes
- README files explain the system to humans and agents; `REPO_INSTRUCTIONS.md` tells agents how to work in this repo
- keep human-facing technical contracts in the nearest owning README, not duplicated in `REPO_INSTRUCTIONS.md`
- use `REPO_INSTRUCTIONS.md` as the agent operating manual and context router
- entry point: `README.md` (human-facing high-level map only)
- workflow contracts: `.github/docs/README.md`
- infra layout, stack ownership, dependency strategy, and phased infra rollout: `infra/README.md`
- module contracts: `infra/modules/**/README.md` (shared contracts live under `infra/modules/aws/_shared/**/README.md`)
- frontend behavior: `frontend/README.md`
- runtime behavior: `lambdas/**/README.md` and `containers/**/README.md`
- before editing, read the relevant local contract docs for the files you plan to touch and follow those contracts
- when adding or reorganizing docs, prefer short README sections that point to the owning nested README rather than expanding the root README with deep implementation detail
- when removing detail from one doc, relocate the content to the owning doc instead of dropping it; it may be shortened or clarified, but the underlying guidance must remain findable in the repo
- keep placeholder-app feature behavior in the directory that owns the code, such as `frontend/**`, `lambdas/**`, or `containers/**`; the root README should link to those docs rather than carry runtime behavior details

## Script Ownership

- reserve `infra/scripts/**` for Terraform or Terragrunt owned helper behavior that is part of the infra runtime contract
- Terragrunt graph rendering, saved-plan metadata lookups, and other helpers that shape the output of Terragrunt commands belong under `infra/scripts/**`, even if a `just` recipe or CI job invokes them
- prefer implementing GitHub Actions or workflow-only helper logic directly in `justfile.ci` when practical
- when a workflow-only helper needs more than a small recipe body, keep its ownership in the CI/workflow layer rather than under `infra/scripts/**`

## Context Loading Order

- load context lazily and only as needed
- start with `REPO_INSTRUCTIONS.md`, then `README.md`
- next read only the relevant contract docs for the capability subset being considered
- only after that inspect implementation files for the selected shape
- avoid loading unrelated capability areas unless the task requires them

## AI Context Summaries

- for broad orientation, read `AI_CONTEXT.md` after this file and the root `README.md`
- for navigation, read `REPO_MAP.md`, `TERRAFORM_INDEX.md`, or `WORKFLOW_INDEX.md` before loading full source files
- after edits, prefer `git diff` and targeted `rg` checks over full-file rereads unless the owning contract is unclear
- escalate to deeper repository inspection when summaries, diffs, and owning README files do not explain dependencies, workflow behavior, graph ordering, or security boundaries

## Context Router

Use indexes to choose files before loading source.

| Task touches | Read next |
| --- | --- |
| workflows, actions, CI, deploy, release, or destroy | `WORKFLOW_INDEX.md`, then `.github/docs/README.md` |
| Terraform, Terragrunt, live stacks, or AWS modules | `TERRAFORM_INDEX.md`, then `infra/README.md` |
| Lambda runtime | `lambdas/README.md`, then matching infra module README when config changes |
| ECS runtime | `containers/README.md`, then matching `task_*` / `service_*` module READMEs when config changes |
| frontend runtime, auth, or hosting | `frontend/README.md`, plus `cognito` / `frontend` infra docs when deployed auth or hosting changes |
| repo-local command surface | owning `justfile*`, then the workflow or infra docs above |
| broad orientation | `AI_CONTEXT.md`, `REPO_MAP.md`, and `CONTEXT_LOADING.md` as needed |

After routing, inspect only impacted implementation files.

## Task Interpretation

- interpret brief requests using this repo's existing patterns and contracts rather than taking them literally
- read the relevant local contract docs before editing and follow them
- prefer the smallest complete change that matches existing repo patterns
- remove stale code, temporary helpers, and abandoned experiment residue as part of the same change rather than leaving dead paths behind
- verify related workflows, infra, docs, and downstream dependencies when the request affects shared behavior
- state material assumptions when the intended shape is not fully explicit
- when ambiguity is material or a wrong assumption could cause the repo shape or contract to drift, ask the user a clarifying question before editing

## Runtime Network Placement

- when changing ECS subnet placement, `assign_public_ip`, NAT, VPC endpoints, or runtime egress, read `infra/README.md#runtime-network-placement` before recommending or editing network changes

## CI OIDC Scope

- when changing CI OIDC roles, deploy permissions, artifact permissions, or `infra/live/ci/aws/oidc/terragrunt.hcl`, read `infra/modules/aws/_shared/oidc/README.md` and `.github/docs/repo-local-actions.md` before editing
- treat the CI OIDC role as artifact-scoped unless the user explicitly asks to change that contract

## Protected Live Stacks

- never remove `aws/oidc`, `aws/ecr`, or `aws/code_bucket` from `infra/live/dev` or `infra/live/ci`
- treat those stacks as protected deployment scaffolding even when pruning an environment to a smaller runtime subset
- if a requested subset appears to exclude one of those protected stacks, keep the stack and call out that it is retained for workflow/bootstrap support

## Feasibility + Dependency Checks (When Editing Infra / Workflows)

- verify the runtime/deploy shape and required backing resources before changing infra or workflow ordering
- for ECS network changes, reason about effective egress; do not infer internet access from subnet names alone
- do not remove VPC endpoints automatically when changing ECS egress; suggest cleanup only after checking all private runtime dependencies
- before adding Terragrunt dependency edges, verify the target live stack exists in that environment and keep graph waves aligned with `just tg-graph-waves <env>`
- when changing reusable workflows, compare caller `with:` blocks to `workflow_call.inputs`, remove dead contract fields, and keep job `name:` values human-readable
- for shared infra plan/apply workflows, keep `task_*` stacks out of infra waves because code deploy owns task-definition rollout
- for cross-stack output passthroughs, ensure downstream Terraform variables match the consumed Terragrunt dependency outputs
- prefer Terragrunt `dependency` inputs plus `mock_outputs` over `terraform_remote_state`; if remote state is intentional, add a `# remote_state_reason: ...` comment
- when introducing or expanding bootstrap/mock-output behavior, update the nearest owning human-facing README
- for detailed checks, read `infra/README.md`, `.github/docs/feasibility-checks.md`, `.github/docs/discovery-and-matrices.md`, and `.github/docs/reusable-workflows.md`

## Terragrunt Plan Expectation

- for a change scoped to one concrete live stack/module, run the targeted plan, for example `just tg dev aws/service_api plan`
- for changes touching multiple stacks, shared modules, Terragrunt dependency edges, workflow ordering, or cross-stack contracts, run the environment plan, for example `just tg-all dev plan`
- do not run both targeted and environment plans unless the first plan exposes a reason to broaden verification
- for noisy plans or logs, write command output under ignored `tmp/` and return only filtered summary lines such as `No changes`, `Plan:`, `Error:`, `Failed`, or relevant `WARN`
- treat saved plans as apply-intent artifacts; do not apply plans that captured bootstrap/mock values
- if credentials, network, permissions, or state access block planning, say so and name the exact manual plan command
- for saved-plan and mock-output details, read `infra/README.md`, `infra/docs/deployment-model.md`, and `.github/docs/artifacts-and-plans.md`

## High-Signal Edit Warnings

- before editing `justfile.ci`, `justfile.deploy`, or `justfile.destroy`, warn the human in commentary that the file is used by automation as well as local commands; for `justfile.destroy`, also warn that it owns destroy commands
- before editing `.github/workflows/shared_*.yml`, warn the human in commentary that shared CI workflows have broad blast radius
- before editing `infra/modules/aws/_shared/**`, warn the human in commentary that shared Terraform modules have broad downstream contract impact
