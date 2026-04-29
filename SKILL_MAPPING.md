# Skill Mapping: aws-serverless-github-deploy

Companion to `portable_repo_skill/SKILL.md`. Concretizes the skill's abstract categories for this repository. Read this before starting any task so you do not re-infer the mapping from scratch.

## Entry-Point Docs

- `README.md` — high-level map and navigation
- `AGENTS.md` — AI agent operating rules; read first
- `.github/docs/README.md` — workflow contracts, job ordering, lifecycle behavior

## Canonical Area Docs

- Root: `README.md`, `AGENTS.md`
- Workflows: `.github/docs/README.md`
- Shared Terraform/Terragrunt modules: `infra/modules/aws/_shared/**/README.md`
- Concrete modules: per-module `README.md` alongside `terragrunt.hcl`

## Shared-Contract Directories

High blast radius — trigger High-Signal Edit Warnings before changing.

- `.github/workflows/shared_*.yml` — reusable workflow contracts called by all environment entry points
- `infra/modules/aws/_shared/` — shared Terraform/Terragrunt modules consumed across stacks

## Runtime-Specific Directories

Lambda code, ECS service definitions, and frontend source are organized by runtime type under their respective top-level directories.

## Workflow and Wrapper Locations

- `.github/workflows/` — all GitHub Actions workflows
- `.github/actions/terragrunt/` — composite action wrapping Terragrunt plan/apply/destroy
- `.github/actions/just/` — composite action wrapping `just` recipes

## Command-Boundary Files

Changes here affect CI behavior directly.

- `justfile` — local developer commands; no AWS mutations
- `justfile.ci` — read-only CI helpers (discovery, validation, checks); must stay non-mutating
- `justfile.tg` — Terragrunt plan artifact helpers (render, upload, download)
- `justfile.deploy` — mutating CI build and deploy steps

## Validation Commands

- `just tf-lint-check` — tflint across all Terraform modules
- `just format` — terraform fmt + terragrunt hclfmt
- `just tg <env> <module> plan` — narrowest infra plan for a single stack

## Protected or High-Blast-Radius Files

- `.github/workflows/shared_infra.yml` — orchestrates the full infra graph across all environments
- `.github/workflows/shared_deploy.yml` — orchestrates all code rollouts
- `.github/actions/terragrunt/action.yml` — plan artifact schema; changes here break all plan/apply flows
- `infra/modules/aws/_shared/` — any output rename is a breaking change to all consumers
- `justfile.deploy` — all deploy operations in CI depend on these recipes
