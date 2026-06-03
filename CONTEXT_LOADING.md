# Context Loading

Use this guide to minimize AI context while preserving the repository's
documentation hierarchy. `REPO_INSTRUCTIONS.md` remains authoritative.

## Level 0: Always

Use the startup wrapper files only to find the authoritative repo guidance.
For active context loading, start with:

- `REPO_INSTRUCTIONS.md`

Then confirm whether the task touches workflows, infrastructure, runtime code,
frontend, or docs.

## Level 1: Architecture

Load when the task needs repo-level orientation:

- `AI_CONTEXT.md`
- `README.md`
- `infra/README.md` for infra topology or stack ownership
- `.github/docs/README.md` for workflow ownership

Example: "Explain how dev deploys work" usually needs Level 0 plus
`AI_CONTEXT.md`, `.github/docs/workflow-entrypoints.md`, and
`infra/docs/deployment-model.md`.

## Level 2: Navigation

Load when choosing exact files:

- `REPO_MAP.md`
- the owning README named by `REPO_INSTRUCTIONS.md`

Example: a task about `service_api` should read
`REPO_MAP.md#terraform-route-map`, `infra/README.md`,
`infra/modules/aws/service_api/README.md`, and
`infra/modules/aws/_shared/service/README.md` before inspecting Terraform.

## Level 3: Implementation

Read only files directly impacted by the task:

- affected `*.tf`, `*.hcl`, workflow YAML, justfile recipe, runtime source, or
  frontend file
- directly related inputs/outputs or manifest files
- nearest owning README when changing behavior or contracts

Prefer targeted commands:

- `git diff -- <path>` before full-file rereads during edits
- `rg <symbol-or-output-name>` for consumers
- `rg --files <directory>` for file shape
- `sed -n '<start>,<end>p' <file>` for focused ranges

Example: adding a Lambda env var should normally inspect the Lambda module
README, the specific live stack, matching module variables/main files, and the
runtime README. Avoid loading unrelated ECS or frontend files.

## Level 4: Debugging

Escalate to deeper inspection only when summaries and focused files are
insufficient:

- Terragrunt graph/wave output
- Terraform plans and saved-plan metadata
- workflow logs
- downstream consumer modules
- runtime logs or local harness output
- related source files outside the original scope

Example: if an infra plan fails because an output is missing, inspect the
producer module output, the consumer variable, the live Terragrunt dependency
block, mocks, and the relevant workflow/plan metadata. Do not scan every module
unless the dependency graph is unclear.

## Practical Patterns

- Read summaries before source code when orientation is needed.
- Prefer diffs over rereading complete files after edits.
- Prefer module/workflow indexes before broad `rg` sweeps.
- Escalate from Level 2 to Level 3 only after identifying the likely owner.
- Escalate to Level 4 when errors, graph shape, saved plans, credentials, or
  external state affect the answer.
