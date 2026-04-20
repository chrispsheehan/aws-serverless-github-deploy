# `paths-filter`

Repo-local GitHub Action and CLI for detecting changed-file categories from git diff, using this repo's own path prefixes.

The GitHub Action runs through this directory's Docker image, so the containerized local path matches the workflow execution path.
The action directory also contains its own `justfile`, but it is only a local test harness.

## Local Usage

Directly on your machine:

```sh
just --justfile .github/actions/paths-filter/justfile local-test --ref main
```

In Docker:

```sh
just --justfile .github/actions/paths-filter/justfile docker-build
just --justfile .github/actions/paths-filter/justfile docker-run --ref main
```

That prints JSON like:

```json
{
  "ref": "main",
  "diffRange": "main..HEAD",
  "changedFiles": [
    ".github/workflows/get_changes.yml",
    "frontend/src/App.jsx"
  ],
  "outputs": {
    "terraform": "false",
    "terragrunt": "false",
    "github": "true",
    "lambdas": "false",
    "containers": "false",
    "frontend": "true"
  }
}
```

## Tests

Local:

```sh
just --justfile .github/actions/paths-filter/justfile test
```

Docker:

```sh
just --justfile .github/actions/paths-filter/justfile docker-build
just --justfile .github/actions/paths-filter/justfile docker-test
```

The tests cover:

- repo-prefix classification for each workflow output
- non-matching paths
- local ref resolution for diff ranges
- end-to-end CLI output from a temporary git repo
