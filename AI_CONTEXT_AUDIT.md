# AI Context Audit

## Documentation Generated

- `AI_CONTEXT.md`: compact repository and architecture overview.
- `REPO_MAP.md`: directory-level navigation guide.
- `TERRAFORM_INDEX.md`: compact Terraform environment/module routing index.
- `WORKFLOW_INDEX.md`: compact workflow routing index.
- `CONTEXT_LOADING.md`: staged context-loading guide.
- `AI_CONTEXT_AUDIT.md`: audit report and savings estimate.
- `REPO_INSTRUCTIONS.md`: brief AI context-loading guidance added.

## Gaps Discovered

- `.github/docs/workflow-entrypoints.md` references
  `dev_infra_plan_and_apply.yml`, but that workflow file is not present.
- `.github/docs/workflow-entrypoints.md` and
  `.github/docs/reusable-workflows.md` reference `shared_infra.yml`, but that
  workflow file is not present.
- `infra/modules/aws/_shared/oidc` contains `verisions.tf`; if intentional this
  is harmless, but it is hard to discover because it differs from the usual
  `versions.tf` naming convention.
- Workflow summaries depend on conventions from `.github/docs`; not every
  workflow has an adjacent focused doc.

## Architectural Risks

- The repo relies on explicit Terragrunt dependency edges and graph-derived
  waves. Hidden or indirect dependencies can break ordering, planability, or
  destroy sequencing.
- Saved plans can capture mock outputs. The repo-local Terragrunt action blocks
  applying mocked plans, but stale saved plan artifacts remain an operational
  risk.
- Task-definition stacks are intentionally excluded from infra apply waves;
  code deploy owns ECS task revision rollout. Mixing those ownership boundaries
  would create drift.
- Production deploys resolve artifacts from CI-owned infrastructure. CI artifact
  stack health is therefore a prerequisite for prod deploys.

## Security Risks

- GitHub OIDC roles are the central trust boundary for CI/CD. The CI OIDC role
  is intentionally narrower than deploy roles and should not be broadened
  casually.
- Public versus private ECS subnet placement affects egress, cost, and exposure.
  Follow `REPO_INSTRUCTIONS.md` before changing `assign_public_ip`, subnet
  discovery, or NAT/VPC endpoint assumptions.
- Database credentials are stored in Secrets Manager and surfaced to runtimes
  through explicit IAM policies. New database consumers should follow the
  existing least-privilege pattern.
- Destroy cleanup can remove retained tagged resources. Keep `destroy.yml` and
  `justfile.destroy` changes isolated and reviewed against `.github/docs/destroy.md`.

## Poor Discoverability

- Workflow docs are split correctly but entry-point docs currently mention
  missing workflow files.
- Live-stack dependency edges are visible in `terragrunt.hcl`, but consumers
  often need `TERRAFORM_INDEX.md` or `REPO_MAP.md` first to avoid loading every
  stack.
- Runtime deploy ownership is split across manifests, justfiles, reusable
  workflows, and Terraform outputs. `WORKFLOW_INDEX.md` should be the starting
  point for future agents.

## Estimated Token Savings

Approximate future-session savings:

- Repo orientation: 60-75% fewer tokens versus reading all README, workflow,
  and module files.
- Terraform module lookup: 60-80% fewer tokens by starting with
  `TERRAFORM_INDEX.md` before opening specific modules.
- Workflow lookup: 55-75% fewer tokens by starting with `WORKFLOW_INDEX.md`
  before reading focused workflow docs.
- Debug sessions: 25-45% fewer tokens when agents follow `CONTEXT_LOADING.md`
  and escalate only from summaries to impacted files.

These savings assume agents still read `REPO_INSTRUCTIONS.md` first and load
owning contract docs before editing behavior.
