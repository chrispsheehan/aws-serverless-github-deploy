# Repo Instructions

These instructions apply to the entire repository.

## Repository Scope

- these instructions apply when the session is launched in this repository
- if the user mentions another local repository or folder, treat it as external reference material unless the user explicitly says to move the work there
- do not assume another repository inherits instructions from this repository

## Template Role

- treat this repository as the deployable template and implementation target unless the user explicitly says otherwise
- when the user supplies a path to different source code, treat that code as reference input by default and make changes in this repository unless the user explicitly redirects the work
- when the user points to another repository, inspect that repository to understand the app shape, product behavior, and capability needs, then propose or implement the corresponding changes in this repository
- prefer translating the external app into this repository's existing platform patterns rather than copying code across verbatim
- treat external repositories as read-only unless the user explicitly requests edits there
- when the external app shape does not map cleanly to this repository, explain the gap, state the closest repo-native deployment shape, and ask the user to confirm before making broad changes

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
- before editing, read the relevant local contract docs for the files you plan to touch and follow those contracts

## Context Loading Order

- load context lazily and only as needed
- start with `REPO_INSTRUCTIONS.md`, then `README.md`
- next read only the relevant contract docs for the capability subset being considered
- only after that inspect implementation files for the selected shape
- avoid loading unrelated capability areas unless the task requires them

## Task Interpretation

- interpret brief requests using this repo's existing patterns and contracts rather than taking them literally
- when a request mentions external source code and asks how to build, make ready, or deploy it, interpret that as "understand the external app, then answer in terms of how this repository should implement or deploy it" unless the user explicitly redirects the work
- read the relevant local contract docs before editing and follow them
- prefer the smallest complete change that matches existing repo patterns
- verify related workflows, infra, docs, and downstream dependencies when the request affects shared behavior
- state material assumptions when the intended shape is not fully explicit
- when ambiguity is material or a wrong assumption could cause the repo shape or contract to drift, ask the user a clarifying question before editing
- for broad product or app-shaping requests, provide a short pre-implementation summary of the inferred app shape, likely capability choices, major assumptions, important questions, and notable cost or security implications before making changes

## Capability Selection

- treat this repo as a menu of optional platform capabilities, not just a single fixed app shape
- infer which capabilities the user is selecting from the request, and which existing capabilities fall outside that target shape
- when the requested shape uses only a subset of the repo's current capabilities, explicitly list the major unused capabilities and ask whether they should be kept for future use or removed
- do not assume that unmentioned capabilities should stay forever, and do not remove them without confirmation
- when a user asks for a website or frontend with a backend but does not specify the backend runtime, prefer the simplest repo-native backend shape as the default starting assumption
- in this repo, default that assumption to a Lambda-backed API unless the user asks for ECS, long-running workers, containers, or another specific runtime
- state that assumption and ask for confirmation before making changes when backend choice materially affects infrastructure shape, cost, or security

## New Repo Bootstrap Requests

- when a request suggests the user is adapting this repo as a fresh app or new project, first determine whether this is a new repo/bootstrap scenario or a change to an existing app
- when the target repo is empty or effectively empty, enter bootstrap flow immediately
- treat a repo as effectively empty when it has no meaningful app, infra, runtime, or workflow code beyond placeholders, starter files, or minimal scaffolding
- if it appears to be a new repo/bootstrap scenario, ask whether the user wants to keep or remove the boilerplate/example application code before making broad changes
- treat clearly labeled example, demo, sample, or boilerplate code as removable only after confirming with the user
- do not delete or replace template/example code solely because a new feature request could be implemented more cleanly without it
- for potentially expensive infrastructure such as load balancers, ECS clusters, or other shared runtime components, ask whether the user wants to keep them for future use or remove them entirely before changing that footprint
- do not assume expensive infrastructure should be deployed, retained, or removed without explicit user confirmation when the request is a bootstrap or simplification scenario
- persist bootstrap-specific questions and user answers in `BOOTSTRAP_DECISIONS.md` so the same questions do not need to be asked repeatedly
- before asking a bootstrap-related clarifying question, check `BOOTSTRAP_DECISIONS.md` first and reuse the recorded answer unless the user changes it
- if the user gives an answer that conflicts with an existing entry in `BOOTSTRAP_DECISIONS.md`, warn that the recorded decision is changing, then update the file
- always consider security during bootstrap and simplification work; if a proposed API would be exposed to the public internet, say that explicitly and suggest at least one more secure option
- do not assume a public unauthenticated API is acceptable just because it is the simplest technical shape
- at the end of a bootstrap or simplification flow, explicitly name any infrastructure that would remain but no longer be used by the proposed app shape, and ask whether the user wants to remove it or keep it for future use

## CI OIDC Scope

- treat `infra/live/ci/aws/oidc/terragrunt.hcl` as intentionally narrow
- the CI OIDC role is for artifact management only: shared code bucket access, current IAM interactions required by CI, and ECR image publishing
- do not broaden the CI role to match the shared `allowed_role_actions` set unless the user explicitly asks for that contract change
- if a task needs deploy permissions, call out that this fails the CI-role scope and name the missing AWS actions/services

## Feasibility + Dependency Checks (When Editing Infra / Workflows)

- verify runtime type (Lambda/ECS), deploy mode, and (for ECS) connection type and load-balancer shape
- verify required infra resources exist (CodeDeploy app/deployment group, listeners/target groups, alarms, VPC link if applicable)
- when changing reusable workflow contracts, compare every caller `with:` block to the callee `workflow_call.inputs`
- when adding or renaming Terraform module `output` values that are intended for Terragrunt `dependency.<name>.outputs` passthrough, verify every downstream consumer wrapper declares a `variable` with the exact same name
- if that same-name output-to-variable contract does not hold yet, do not leave it implicit: either add the matching variables, or call out the mismatch explicitly before closing the task
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

- before editing `justfile.destroy`, print an explicit terminal warning in commentary (destroy command ownership boundary)
- before editing `.github/workflows/shared_*.yml`, print an explicit terminal warning in commentary (shared CI workflow blast radius)
- before editing `infra/modules/aws/_shared/**`, print an explicit terminal warning in commentary (shared-contract blast radius)
