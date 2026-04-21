# `get-changes`

Repo-local GitHub Action and CLI for classifying changed files into the repo's standard CI buckets.

The GitHub Action runs through this directory's Docker image, so the local Docker path matches the workflow execution path.
Inside GitHub Actions, the script resolves the checkout from `GITHUB_WORKSPACE` and marks it as a git `safe.directory` before reading git state.

Default path buckets:

- `actions`: `.github/actions/**`
- `terraform`: `infra/modules/**`
- `terragrunt`: `infra/**`
- `github`: `.github/**`
- `lambdas`: `lambdas/**`
- `containers`: `containers/**`
- `frontend`: `frontend/**`

Inputs:

- `ref`: fallback ref to compare from, default `main`
- `base_ref`: optional explicit PR base ref or SHA; when present the action compares `base_ref...HEAD`

## Local Usage

Directly on your machine:

```sh
just --justfile .github/actions/get-changes/justfile local-test --ref main
```

In Docker:

```sh
just --justfile .github/actions/get-changes/justfile docker-build
just --justfile .github/actions/get-changes/justfile docker-run --ref main
```

## Tests

Local:

```sh
just --justfile .github/actions/get-changes/justfile unit-test
```

Docker:

```sh
just --justfile .github/actions/get-changes/justfile docker-build
just --justfile .github/actions/get-changes/justfile docker-unit-test
```
