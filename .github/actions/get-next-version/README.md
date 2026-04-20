# `get-next-version`

Repo-local GitHub Action and CLI for computing the next plain semver tag from commit subject prefixes since the latest semver tag.

The GitHub Action itself runs through the same Docker image defined in this directory's `Dockerfile`, so the containerized local test path matches the CI execution path.
The action directory also contains its own `justfile`, but it is only a local test harness; the Docker action itself runs the Python entrypoint directly.

## Local Usage

Directly on your machine:

```sh
just --justfile .github/actions/get-next-version/justfile local-test \
  --major-prefixes breaking,major \
  --minor-prefixes feat,minor \
  --patch-prefixes fix,chore
```

In Docker:

```sh
just --justfile .github/actions/get-next-version/justfile docker-build
just --justfile .github/actions/get-next-version/justfile docker-run \
  --major-prefixes breaking,major \
  --minor-prefixes feat,minor \
  --patch-prefixes fix,chore
```

Feasibility preflight:

```sh
just --justfile .github/actions/get-next-version/justfile feasibility-test \
  --major-prefixes breaking,major \
  --minor-prefixes feat,minor \
  --patch-prefixes fix,chore
```

Docker feasibility preflight:

```sh
just --justfile .github/actions/get-next-version/justfile docker-build
just --justfile .github/actions/get-next-version/justfile docker-feasibility-test \
  --major-prefixes breaking,major \
  --minor-prefixes feat,minor \
  --patch-prefixes fix,chore
```

Default JSON output:

```json
{"currentVersion":"0.14.0","version":"0.14.1","hasNextVersion":"true","bump":"patch"}
```
