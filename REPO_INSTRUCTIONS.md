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

- do not assume ECS services must run in private subnets
- when a service needs outbound internet access, explicitly ask whether the runtime should run in public subnets or private subnets before recommending NAT gateways
- only recommend NAT gateways when private subnet placement is required, explicitly chosen, or otherwise necessary for the selected security model
- if a service can safely run in public subnets, call out that public subnet placement with task public IPs may be the lower-cost deployment shape and explain the security implications
- for public-subnet ECS services, require a clear ingress model before implementation: public load balancer or API Gateway path, security group restrictions, authentication requirements, and whether tasks should receive public IPs
- for scraper, polling, webhook, or external-API-heavy services, treat subnet placement as an explicit architecture decision because outbound connectivity affects architecture, cost, and security
- do not list NAT as an AWS prerequisite unless the selected runtime placement uses private subnets and needs outbound internet access

## CI OIDC Scope

- treat `infra/live/ci/aws/oidc/terragrunt.hcl` as intentionally narrow
- the CI OIDC role is for artifact management only: shared code bucket access, current IAM interactions required by CI, and ECR image publishing
- do not broaden the CI role to match the shared `allowed_role_actions` set unless the user explicitly asks for that contract change
- if a task needs deploy permissions, call out that this fails the CI-role scope and name the missing AWS actions/services

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

- for changes that can affect Terraform evaluation or plan output, run `just tg-all dev plan` before closing when feasible
- use `just tg-all <env> plan` as the default infra verification surface; targeted `just tg <env> <module> validate` or focused plans are debugging aids, not replacements
- for shared modules or cross-stack contracts, rely on the environment plan to cover downstream consumers
- treat saved plans as apply-intent artifacts; do not apply plans that captured bootstrap/mock values
- if credentials, network, permissions, or state access block planning, say so and name the exact manual plan command
- for saved-plan and mock-output details, read `infra/README.md`, `infra/docs/deployment-model.md`, and `.github/docs/artifacts-and-plans.md`

## High-Signal Edit Warnings

- before editing `justfile.ci`, `justfile.deploy`, or `justfile.destroy`, warn the human in commentary that the file is used by automation as well as local commands; for `justfile.destroy`, also warn that it owns destroy commands
- before editing `.github/workflows/shared_*.yml`, warn the human in commentary that shared CI workflows have broad blast radius
- before editing `infra/modules/aws/_shared/**`, warn the human in commentary that shared Terraform modules have broad downstream contract impact
