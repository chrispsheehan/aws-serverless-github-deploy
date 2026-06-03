# Repository Map

Directory routing only. This file is for choosing where to look next, not for
understanding detailed contracts.

| Path | Purpose | Read Next |
| --- | --- | --- |
| `REPO_INSTRUCTIONS.md` | Authoritative agent operating manual and context router. | Start here for every task. |
| `AGENTS.md`, `CLAUDE.md` | Identical wrappers that route agents to `REPO_INSTRUCTIONS.md`. | Do not diverge them. |
| `README.md` | Human-facing repo overview. | Use after `REPO_INSTRUCTIONS.md` for broad orientation. |
| `docs` | Local setup and general supporting docs. | `docs/get-started-locally.md`. |
| `.github/workflows` | CI, release, infra plan/apply, code deploy, and destroy workflows. | `WORKFLOW_INDEX.md`, then `.github/docs/README.md`. |
| `.github/docs` | Workflow contracts and workflow-doc router. | Pick the focused doc named by `.github/docs/README.md`. |
| `.github/actions` | Repo-local GitHub Actions. | `.github/docs/repo-local-actions.md`, then the action README. |
| `infra` | Terraform/Terragrunt infrastructure. | `infra/README.md`, then `TERRAFORM_INDEX.md`. |
| `infra/live` | Environment-specific Terragrunt stacks. | Affected `terragrunt.hcl` files after identifying the stack. |
| `infra/modules/aws/_shared` | Reusable Terraform building blocks. | `TERRAFORM_INDEX.md`, then the shared module README. |
| `infra/modules/aws/<module>` | Repo-specific Terraform modules and wrappers. | `TERRAFORM_INDEX.md`, then the module README. |
| `infra/docs` | Infra deployment model and Terragrunt graph helpers. | `deployment-model.md` or `terragrunt-graph-helpers.md`. |
| `lambdas` | Lambda source, shared Lambda helpers, and deploy manifest. | `lambdas/README.md`, `lambdas/deploy.yml`. |
| `containers` | ECS source, shared ECS helpers, and deploy manifest. | `containers/README.md`, `containers/deploy.yml`. |
| `frontend` | Vite frontend app. | `frontend/README.md`. |
| `config/deploy` | Lambda/ECS CodeDeploy AppSpec templates. | `.github/docs/reusable-workflows.md`, deploy justfile recipes. |
| `config/otel` | OpenTelemetry collector config. | ECS task modules and container README. |
| `lib` | Shared Python runtime helpers. | Relevant Lambda/container README. |
| `local` | Local harnesses and emulation config. | Runtime README and local setup docs. |
| `justfile*` | Local, CI, deploy, and destroy command surfaces. | `infra/README.md` or `.github/docs/README.md` depending on recipe ownership. |

## Routing Shortcuts

- Terraform/module work: `TERRAFORM_INDEX.md` first, then the owning module
  README and targeted source files.
- Workflow work: `WORKFLOW_INDEX.md` first, then `.github/docs/README.md` and
  the focused workflow doc.
- Runtime work: the runtime README first, then matching manifest and source.
- Cross-cutting deploy work: `AI_CONTEXT.md`, `infra/docs/deployment-model.md`,
  `WORKFLOW_INDEX.md`, and `TERRAFORM_INDEX.md`.
