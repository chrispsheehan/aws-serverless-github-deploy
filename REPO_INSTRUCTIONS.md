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

## Context Router

| Task touches | Read next |
| --- | --- |
| `.github/workflows/**` or `.github/actions/**` | `.github/docs/README.md`, then the focused workflow doc it routes to |
| `infra/live/**` | `infra/README.md`, then the affected `infra/modules/**/README.md` |
| `infra/modules/aws/_shared/**` | the affected `_shared/**/README.md` plus downstream concrete module READMEs when relevant |
| `infra/modules/aws/<module>/**` | `infra/README.md` and `infra/modules/aws/<module>/README.md` |
| `lambdas/**` | `lambdas/README.md`, the affected Lambda README, and the matching infra module README when behavior or configuration changes |
| `containers/**` | `containers/README.md`, the affected service README, and matching `task_*` / `service_*` infra module READMEs when behavior or configuration changes |
| `frontend/**` | `frontend/README.md`, plus `infra/modules/aws/frontend/README.md` and `infra/modules/aws/cognito/README.md` when deployed hosting or auth changes |
| `justfile.ci`, `justfile.deploy`, or reusable workflow behavior | `.github/docs/README.md`, then `reusable-workflows.md`, `artifacts-and-plans.md`, or `discovery-and-matrices.md` as relevant |
| `justfile.destroy` | `.github/docs/README.md` and `.github/docs/destroy.md` before editing |
| external app adaptation, placeholder replacement, template simplification, or app bootstrapping | `docs/agent/app-shaping.md` |

## Task Interpretation

- interpret brief requests using this repo's existing patterns and contracts rather than taking them literally
- when a request mentions external source code and asks how to build, make ready, or deploy it, interpret that as "understand the external app, then answer in terms of how this repository should implement or deploy it" unless the user explicitly redirects the work
- read the relevant local contract docs before editing and follow them
- prefer the smallest complete change that matches existing repo patterns
- remove stale code, temporary helpers, and abandoned experiment residue as part of the same change rather than leaving dead paths behind
- verify related workflows, infra, docs, and downstream dependencies when the request affects shared behavior
- state material assumptions when the intended shape is not fully explicit
- when ambiguity is material or a wrong assumption could cause the repo shape or contract to drift, ask the user a clarifying question before editing
- for broad product or app-shaping requests, provide a short pre-implementation summary of the inferred app shape, likely capability choices, major assumptions, important questions, and notable cost or security implications before making changes

Example requests to interpret through these repo-native rules:

```text
add a new environment called qa
```

```text
Give me a site with a backend and a database
```

```text
look at ../sandbox and tell me how to deploy
```

## Capability Selection

- treat this repo as a menu of optional platform capabilities, not just a single fixed app shape
- infer which capabilities the user is selecting from the request, and which existing capabilities fall outside that target shape
- when the requested shape uses only a subset of the repo's current capabilities, explicitly list the major unused capabilities and ask whether they should be kept for future use or removed
- do not assume that unmentioned capabilities should stay forever, and do not remove them without confirmation
- when a user asks for a website or frontend with a backend but does not specify the backend runtime, prefer the simplest repo-native backend shape as the default starting assumption
- in this repo, default that assumption to a Lambda-backed API unless the user asks for ECS, long-running workers, containers, or another specific runtime
- state that assumption and ask for confirmation before making changes when backend choice materially affects infrastructure shape, cost, or security

## Runtime Network Placement

- do not assume ECS services must run in private subnets
- when adapting an app that needs outbound internet access, explicitly ask whether the runtime should run in public subnets or private subnets before recommending NAT gateways
- only recommend NAT gateways when private subnet placement is required, explicitly chosen, or otherwise necessary for the selected security model
- if a service can safely run in public subnets, call out that public subnet placement with task public IPs may be the lower-cost deployment shape and explain the security implications
- for public-subnet ECS services, require a clear ingress model before implementation: public load balancer or API Gateway path, security group restrictions, authentication requirements, and whether tasks should receive public IPs
- for scraper, polling, webhook, or external-API-heavy services, treat subnet placement as an app-shaping decision because outbound connectivity affects architecture, cost, and security
- do not list NAT as an AWS prerequisite unless the selected runtime placement uses private subnets and needs outbound internet access

## App Shaping Flow

When the user is adapting an external app, replacing the placeholder app, simplifying the template, or bootstrapping a new app from this repo, read and follow `docs/agent/app-shaping.md` before proposing or editing the app shape.

Keep this high-level contract in mind even before loading the detailed flow:

- determine additive versus replacement intent unless it is already clear
- determine selected capabilities and list major unused capabilities rather than assuming they should stay forever
- record durable app-shaping answers in `BOOTSTRAP_DECISIONS.md`
- align local development, workflows, infra stacks, runtime code, docs, and verification commands with the selected app shape
- always surface public exposure, authentication, cost, bootstrap implications, and any needed README/context refresh before closing the task

## Bootstrap Operations

- at the end of app-shaping work, offer the next operational bootstrap steps needed to make the selected app shape real end to end
- for AWS-backed deployments, this usually includes creating or updating GitHub OIDC roles, applying foundational stacks in dependency order, deploying initial infrastructure, publishing first runtime artifacts, running migrations, and seeding initial users when Cognito is enabled
- before the first plan, apply, prerequisite check, or other AWS interaction in a task, confirm which AWS role, user, and account will be used
- do not run AWS-mutating bootstrap commands without explicit user approval
- when offering OIDC setup, name the exact commands, for example `just tg ci aws/oidc apply`, `just tg dev aws/oidc apply`, or `just tg prod aws/oidc apply`
- when offering first environment setup, separate infra bootstrap from code deployment and call out any prerequisite shared resources such as VPCs, tagged subnets, hosted zones, ECR images, code buckets, or Terraform state

## CI OIDC Scope

- treat `infra/live/ci/aws/oidc/terragrunt.hcl` as intentionally narrow
- the CI OIDC role is for artifact management only: shared code bucket access, current IAM interactions required by CI, and ECR image publishing
- do not broaden the CI role to match the shared `allowed_role_actions` set unless the user explicitly asks for that contract change
- if a task needs deploy permissions, call out that this fails the CI-role scope and name the missing AWS actions/services

## Feasibility + Dependency Checks (When Editing Infra / Workflows)

- verify runtime type (Lambda/ECS), deploy mode, and (for ECS) connection type and load-balancer shape
- verify required infra resources exist (CodeDeploy app/deployment group, listeners/target groups, alarms, VPC link if applicable)
- before adding a Terragrunt `dependency` or `dependencies` path, verify the target live stack actually exists in that environment/repo slice
- when changing reusable workflow contracts, compare every caller `with:` block to the callee `workflow_call.inputs`
- when a workflow input, output, or metadata field is no longer consumed, remove it from the shared contract and callers in the same change rather than leaving dead plumbing behind
- when changing Terragrunt `*.hcl` dependency edges, re-check the derived infra wave count; the current shared module-discovery/workflow contract only exposes `wave_0_modules`, `wave_1_modules`, and `wave_2_modules`
- when adding or renaming Terraform module `output` values that are intended for Terragrunt `dependency.<name>.outputs` passthrough, verify every downstream consumer wrapper declares a `variable` with the exact same name
- if that same-name output-to-variable contract does not hold yet, do not leave it implicit: either add the matching variables, or call out the mismatch explicitly before closing the task
- check apply/deploy/destroy, and avoid unnecessary `terraform_remote_state` coupling (especially for fast-changing outputs)
- for bootstrap-sensitive or plan-sensitive cross-stack contracts, prefer Terragrunt `dependency` inputs in the live stack and `mock_outputs` for non-mutating commands rather than reading upstream state directly inside Terraform modules
- if CI plan failures are caused by missing upstream state, fix the contract shape first instead of papering over the issue with more direct `terraform_remote_state` reads
- keep this approach visible to users as well: when you introduce or expand this pattern, update the nearest owning human-facing README, usually `infra/README.md` or the affected module README, so the bootstrap-friendly mock strategy is documented outside agent-only instructions
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
