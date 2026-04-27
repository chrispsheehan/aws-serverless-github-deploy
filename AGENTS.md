# Repo Instructions

## Common Elevations

- request escalation for `just tg <env> <module> validate` when Terragrunt needs normal network or AWS access outside the sandbox
- request escalation for `just tg <env> <module> plan` when Terragrunt needs normal network, AWS, or remote-state access outside the sandbox
- request escalation for `just tg-all <op>` when the command needs real Terragrunt/Terraform access beyond sandbox limits
- when one of those commands is relevant to the task, ask for escalation immediately before running it rather than failing inside the sandbox first
- use stable command prefixes where possible so repeated `just tg` escalations can be approved and reused consistently

## Documentation

Update documentation in the same change:

- update the repo root `README.md` for cross-cutting behavior changes
- update affected module `README.md` files under `infra/modules/**` for module contract or responsibility changes
- when changing `.github/workflows/**`, update `.github/docs/README.md` if job dependencies, reusable workflow contracts, lifecycle ordering, workflow-call structure, or downstream feasibility checks changed
- keep `.github/docs/README.md` as the source of truth for workflow contracts and CI feasibility checks
- prefer Mermaid diagrams in `.github/docs/README.md` that show jobs, `needs`, and reusable-workflow relationships rather than trying to reproduce the exact GitHub Actions UI
- when adding a new AWS infra type or service family, check whether the deploy role in `infra/live/global_vars.hcl` needs additional `allowed_role_actions` and update it in the same change if required
- when changing the set of deployable Lambda or ECS runtimes, check whether the shared `observability` dashboard still reflects the current runtime surface and update it in the same change if needed

### Documentation Architecture

- treat the repo root `README.md` as the entry point and high-level map, not the canonical home for detailed module behavior
- keep cross-cutting summaries in the root `README.md`, with links to the canonical module docs for technical detail
- treat `infra/modules/aws/_shared/**/README.md` files as the canonical source for shared runtime behavior, deployment strategies, connection types, drift ownership, and feasibility constraints
- treat concrete module `README.md` files under `infra/modules/**` as specialization docs: describe what the module owns, what it depends on, and how it narrows or extends the shared-module contract
- treat `lambdas/**/README.md` and `containers/**/README.md` as the canonical place for runtime-specific business logic, request/worker behavior, integration assumptions, and operational notes for that runtime
- when a behavior is primarily shared-module logic, update the relevant `_shared` README first and only keep a short summary or link in the root `README.md`
- prefer reading documentation before code for initial context; use code to verify implementation details or resolve doc/code drift
- if docs and code conflict, call out the mismatch explicitly and fix the relevant docs in the same change when behavior is being changed
- structure module READMEs so they help both humans and agents isolate reasoning; prefer sections such as `Owns`, `Does Not Own`, `Inputs That Change Behavior`, `Outputs Consumers Rely On`, `Decision Rules`, `Feasibility Constraints`, `Dependency Notes`, `CI / Deploy Expectations`, and `Drift / Ownership Rules` when they apply
- when changing a Lambda or ECS runtime's actual application logic, add or update the nearest runtime README in the same change so the docs explain what that code does at a human-readable level

## CI OIDC Scope

- treat `infra/live/ci/aws/oidc/terragrunt.hcl` as intentionally narrow
- the CI OIDC role is for artifact management only: shared code bucket access, current IAM interactions required by CI, and ECR image publishing
- do not broaden the CI role to match the shared `allowed_role_actions` set unless the user explicitly asks for that contract change
- if a task needs deploy permissions, call out that this fails the current CI-role scope and document the exact additional AWS actions or services required

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
- keep detailed deployment-strategy and connection-type rules in the relevant `_shared` module README, and update those docs when the feasibility contract changes
- check feasibility downstream on every change, not just in the module being edited; verify that consumers, workflows, remote-state readers, deploy wrappers, and destroy paths still match the updated contract

## CI Dependency Safety

When changing CI workflows or Terraform module dependencies, check dependency behavior across the full lifecycle, not just the happy path.

- check apply, deploy, and destroy behavior
- on destroy, prefer depending on the real downstream stacks rather than serializing shared stacks unnecessarily; for example, `network` and `cluster` can tear down in parallel once their consuming service, task, and frontend stacks are gone
- when a workflow calls a reusable workflow, compare the caller `with:` block against the callee `workflow_call.inputs` block before editing anything else
- do that check for every caller of the reusable workflow, not just the file you started in
- treat optional inputs as part of the contract too; verify that each caller is intentionally relying on a default rather than silently omitting an input it actually needs
- if a caller needs data that can be derived inside an existing reusable workflow, prefer adding an explicit reusable-workflow output over adding a new wrapper job just to rediscover the same data
- `infra_releases.yml` is release-time artifact preparation for shared CI resources; do not add it to prod deploy wrappers unless the user explicitly wants deploy-time artifact creation there
- for `*_code` deploy wrappers, check that the dispatch inputs actually cover every runtime being deployed; if ECS deploys are included, the wrapper must expose or deliberately derive an `ecs_version`
- when the same setup or lookup pattern appears in multiple workflows, suggest extracting it into a shared reusable workflow or shared `just` recipe instead of repeating it
- if you add helper code under `containers/`, check the `just` directory-discovery recipes so CI does not accidentally treat that directory as a deployable ECS image target
- check workflow dependency wiring such as `needs`, job outputs, matrix values, and reused workflow inputs
- watch for `data.terraform_remote_state` dependencies that can fail if another stack has not been created yet or has already been destroyed
- prefer `data.terraform_remote_state` only for outputs that are stable and rarely changed; avoid using it as the normal handoff for values that commonly change during the same infra rollout, such as task definition arns, API routing identifiers, auth client details, queue wiring, or other active runtime/deploy outputs
- avoid cross-runtime ownership when a resource is really part of one app shape; for example, keep the ECS worker queue with `task_worker` rather than making ECS consume `lambda_worker` state
- when a bootstrap path needs placeholder values, prefer hiding that conditional logic in locals instead of repeating `count`-indexed remote-state references through the module body
- if you do add a genuinely new stack type, update the discovery and lifecycle workflows too: `get_directories.yml`, `infra.yml`, and `destroy.yml`
- if you add, rename, or remove a runtime whose logs should appear in the shared CloudWatch dashboard, update the `observability` stack so the dashboard queries stay aligned with the current infra and feature-code shape
- check required Terraform input variables on destroy paths as well as apply paths; destroy can still fail before resource deletion if required vars are unset
- make sure every referenced `needs.<job>.outputs.*` value is actually in scope for that job
- make sure matrix values match the expected naming contract for the workflow, module, or path being used
- for `*_infra` wrappers, verify they stop at infrastructure apply and do not also run the reusable `deploy.yml` code rollout
- for prod wrappers in this repo, remember that shared artifact resources come from `ci`, while deploy target resources are still in `prod`
- prefer making modules tolerant of unnecessary upstream state dependencies where possible
- do not change CI ordering blindly; first check whether the real issue is an avoidable cross-stack dependency

## Terragrunt Plan Expectation

- when a change touches `*.hcl`, Terraform modules, live Terragrunt stacks, or downstream dependencies that can affect Terraform evaluation or plan output, run the relevant `just tg <env> <module> plan` command before closing the task when feasible
- choose the smallest relevant plan surface rather than defaulting to `run-all`; for example, plan only the affected `dev`, `ci`, or `prod` stack(s)
- when shared modules or remote-state contracts change, consider the downstream consumer stacks too and run plans for the affected dependents, not just the module wrapper you edited
- if a plan is not feasible because credentials, network, permissions, or state access are unavailable, say that explicitly in the final response and name the plan command that should be run manually

## Justfile Change Warning

- treat `justfile.ci` and `justfile.deploy` as high-signal command-boundary files
- before editing either file, print an explicit terminal warning to the user in commentary that the change touches CI/deploy command ownership
- that warning should call out that workflow callers, `justfile_path` usage, and recipe ownership boundaries may also need updates
- format that warning as a conspicuous ANSI-colored block when possible, for example with red bold text, so it stands out in the terminal
- emit that warning as the last commentary message immediately before the edit tool call, so it stays visible in the terminal rather than scrolling off during earlier exploration

## Shared Infra Change Warning

- treat `infra/modules/aws/_shared/**` as a high-signal shared-contract area
- before editing files under `infra/modules/aws/_shared/**`, print an explicit terminal warning to the user in commentary that the change touches shared infra behavior and may affect multiple downstream modules, live stacks, workflows, and docs
- that warning should call out that remote-state consumers, wrapper workflows, destroy paths, and `_shared` README contracts may also need updates
- format that warning as a conspicuous ANSI-colored block when possible, for example with red bold text, so it stands out in the terminal
- emit that warning as the last commentary message immediately before the edit tool call, so it stays visible in the terminal rather than scrolling off during earlier exploration
