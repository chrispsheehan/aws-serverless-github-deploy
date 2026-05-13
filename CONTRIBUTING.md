# Contributing

## Docs Expectations

Keep documentation aligned with code changes:

- CI/CD behavior
- Terraform module inputs or outputs
- deployment strategy
- bootstrap behavior
- operator-facing commands

Also update the affected module `README.md` files under `infra/modules/**` whenever module responsibilities, dependencies, inputs, or outputs change.

## AI-Assisted Changes

AI-assisted changes should follow the same repo contracts as manual changes:

- read the nearest owning README before changing code
- keep docs aligned with workflow/module/runtime changes
- when HCL or Terraform dependencies change, run the smallest relevant `just tg <env> <module> plan` or `validate` when feasible (or call out why it could not be run)

## Working Style

- keep module READMEs short and operational
- prefer updating existing docs in the same PR rather than leaving follow-up documentation tasks
