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

AI-assisted changes are expected to follow the same repo contracts as manual changes.

- prefer reading the nearest owning README before changing code
- keep the root `README.md` focused on entry-point guidance; put detailed behavior in the owning workflow, runtime, or module docs
- when changing workflow contracts, update `.github/docs/README.md` in the same PR
- when changing shared module behavior, update the relevant `infra/modules/**/README.md` in the same PR
- when changing runtime behavior, update the nearest `lambdas/**/README.md` or `containers/**/README.md`
- when HCL or downstream Terraform dependencies change, run the smallest relevant `just tg <env> <module> plan` or `validate` command when feasible and call out any environment limits if you cannot run it

## Working Style

- keep module READMEs short and operational
- prefer updating existing docs in the same PR rather than leaving follow-up documentation tasks
