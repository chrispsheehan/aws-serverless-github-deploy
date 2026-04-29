---
name: repo-governance-maintainer
description: Use when working in an unfamiliar repository that has layered documentation, shared modules, CI or deployment workflows, and contract-sensitive infrastructure or application changes. This skill teaches Codex to map ownership boundaries first, read canonical docs before code, make the smallest viable change, update documentation in the same change, check downstream lifecycle effects, and warn before editing high-signal shared or command-boundary files. Appropriate for repo extension, refactors, CI workflow changes, infra changes, and other tasks where local correctness is not enough and downstream consumers or lifecycle paths may break.
---

# Repo Governance Maintainer

Apply this skill when a repo expects disciplined change management rather than isolated file edits.

## Goals

- Understand the repo by ownership boundaries before changing code.
- Prefer the smallest viable change that satisfies the request.
- Treat docs, workflows, shared modules, and validation commands as part of the implementation.
- Check downstream consumers and lifecycle behavior, not just the edited files.

## First Pass

Start by finding the repo's instruction and documentation surface:

- Read `AGENTS.md` if present.
- Read the root `README.md` as the entry point.
- Identify canonical docs for each area before reading code.
- Look for directories that imply shared ownership, reusable workflows, runtime-specific code, or deployment wrappers.

Do not assume the root README is the detailed source of truth. Treat it as the map unless the repo clearly uses a different pattern.

## Canonical Doc Mapping

Before editing, infer which docs are authoritative for the area you are touching:

- Root docs: high-level map, cross-cutting behavior, navigation.
- Shared-module docs: reusable behavior, contracts, feasibility rules, ownership boundaries.
- Concrete module docs: specialization, inputs, outputs, dependencies, narrowing of shared behavior.
- Runtime or app docs: business logic, operational notes, integration assumptions.
- Workflow docs: reusable workflow contracts, job ordering, required inputs, lifecycle behavior.

If docs and code disagree, call out the mismatch explicitly. If behavior changes, update the relevant docs in the same change.

## Working Rules

### 1. Read docs before code

Use documentation to locate the contract. Use code to verify implementation details or resolve drift.

### 2. Preserve ownership boundaries

Keep resources, logic, and responsibility with the component that truly owns them. Avoid creating unnecessary cross-component coupling just because state or outputs are reachable.

### 3. Prefer the smallest viable change

Do not widen scope unless the requested behavior requires it. If a larger contract change is needed, state that clearly.

### 4. Update docs with the change

When behavior, contracts, workflow dependencies, or runtime responsibilities change, update the corresponding docs in the same patch.

### 5. Validate downstream effects

Check consumers, wrappers, callers, destroy paths, and dependent stacks or modules. Local edits are insufficient if the repo has reusable contracts.

## Feasibility Check

Before implementing a deployment, workflow, infra, or contract-sensitive request, verify that the requested combination is feasible in the current repo shape.

Check:

- the target runtime or component type
- the requested deployment or execution mode
- the connection or exposure model, if relevant
- whether required supporting resources already exist
- whether current workflows, wrappers, or remote-state readers can support the change

If the combination is invalid or incomplete:

- say that it fails the feasibility check
- explain the missing requirement
- describe the smallest change needed to make it feasible

## Lifecycle Safety

When changing workflows, dependency wiring, or infrastructure contracts, check the full lifecycle:

- create or apply
- deploy or rollout
- destroy or teardown

Verify:

- caller inputs match callee contracts
- optional inputs are intentionally omitted rather than forgotten
- outputs referenced by downstream jobs or modules actually exist
- dependency ordering reflects real requirements rather than accidental serialization
- remote state or cross-stack reads are stable enough for the values being consumed

Prefer deriving shared data once in the reusable layer and exposing it as an explicit output rather than recomputing it in many wrappers.

## High-Signal Edit Warnings

Before editing a high-signal boundary, emit a conspicuous warning in your response immediately before the edit — not after.

High-signal boundaries usually include:

- shared reusable modules
- deployment wrappers or CI command surfaces
- reusable workflows
- global policy or permission definitions

The warning must:

1. Name the file or boundary being changed
2. List the likely blast radius (downstream modules, callers, remote-state consumers, destroy paths, docs, validation commands)
3. State whether the change is additive (low risk) or destructive/renaming (breaking until callers are updated)
4. Follow the repo's local operating model: if the repo requires confirmation, ask for it; if the repo requires a warning-but-continue model, warn clearly and proceed

Do not proceed past a high-signal boundary warning silently. If operating autonomously, follow the repo-local contract rather than imposing a generic stop rule.

## Contradiction Warnings

If you discover something that is at odds with this skill's operating model, warn explicitly instead of silently adapting.

Examples:

- the docs are not actually authoritative for the area they claim to cover
- the codebase relies on cross-component ownership that violates the expected boundaries
- the smallest viable change is not possible because the contract is already inconsistent
- the requested change requires broadening permissions, workflow scope, or deployment ownership
- required validation cannot be run, or the repo has no narrow validation surface for the affected area
- caller, callee, or downstream lifecycle contracts are already broken before your change

In that warning:

- state what conflicts with the skill
- say whether it is a pre-existing repo condition or introduced by the request
- explain the practical risk
- say whether you can still proceed safely, and under what limitation

## Validation Strategy

Decide which validation tier applies before running anything:

1. **Attempt validation** when credentials, network, and environment are available and the scope is narrow enough to run without risk.
2. **State the command** when validation is blocked by credentials, permissions, network, or environment limits — name the exact command that must be run manually, and in which environment.
3. **Skip and warn** when no narrow validation surface exists for the affected area — say so explicitly rather than running a broad sweep that would produce noise or side effects.

Do not default to option 1 in CI or infrastructure contexts without confirming that ambient credentials are available and scoped correctly. Do not default to option 3 without first checking whether a targeted command exists.

Examples of targeted validation:

- targeted tests instead of full-suite runs
- the narrowest affected plan instead of a full multi-stack run
- only the callers and workflows affected by a reusable workflow change

## Change Classification

Before making a change, classify it:

**Additive** — new optional input, new output, new module, new workflow step that existing callers can ignore. Low risk. Proceed with standard checks.

**Destructive or renaming** — removing or renaming an output, input, variable, or module that is referenced downstream. Treat as breaking until all callers are updated in the same patch. Do not make a destructive change in a shared boundary without updating every consumer in the same change, or explicitly handing off that follow-on work to the user.

**Behavior-preserving restructure** — moving logic without changing inputs or outputs. Medium risk. Verify callers and destroy paths still work.

When in doubt, prefer additive changes. If the request requires a destructive change, say so before proceeding and follow the repo-local confirmation or warning contract for shared boundaries.

## Editing Heuristics

- Prefer contract-preserving changes over broad restructures.
- Keep naming and directory conventions aligned with the repo's existing patterns.
- If the same setup or lookup logic appears repeatedly, consider extracting a shared helper rather than duplicating it again.
- Hide bootstrap or placeholder conditionals in one place when possible instead of scattering fragile checks through the codebase.
- Avoid changing permission scope, workflow scope, or deployment ownership unless the user explicitly wants that contract change.

## Recommended Doc Sections

When adding or restructuring module-level docs, prefer sections like:

- `Owns`
- `Does Not Own`
- `Inputs That Change Behavior`
- `Outputs Consumers Rely On`
- `Decision Rules`
- `Feasibility Constraints`
- `Dependency Notes`
- `CI / Deploy Expectations`
- `Drift / Ownership Rules`

Use only the sections that materially help the reader isolate reasoning.

## Response Expectations

In your final response:

- summarize the actual change
- note what docs were updated
- list the validation performed
- explicitly call out any validation you could not run
- mention feasibility or lifecycle risks that remain

## Adapting This Skill To A New Repo

At the start of each task, quickly map these repo-specific equivalents:

- entry-point docs
- canonical area docs
- shared-contract directories
- runtime-specific directories
- workflow and wrapper locations
- command-boundary files
- validation commands
- protected or high-blast-radius files

Once mapped, follow the same workflow without assuming the original repo's tooling or cloud provider.

If the repo provides a companion `SKILL_MAPPING.md`, read it before starting. It concretizes these equivalents for that specific repo so you do not need to re-infer them.
