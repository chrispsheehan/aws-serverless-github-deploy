# `get-next-version`

Repo-local GitHub Action and CLI for computing the next plain semver tag from commit subject prefixes since the latest semver tag.

The GitHub Action itself runs through the same Docker image defined in this directory's `Dockerfile`, so the containerized local test path matches the CI execution path.
The action directory also contains its own `justfile`, but it is only a local test harness; the Docker action itself runs the Python entrypoint directly.
Inside GitHub Actions, the script resolves the checkout from `GITHUB_WORKSPACE` rather than assuming a fixed Docker working directory.

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

That preflight covers:

- direct pushes with patch, minor, and major prefixes
- squash/rebase PR subjects
- default merge-commit subjects that should not match
- case-insensitive prefix matching
- mixed commit lists where the highest bump level should win

Workspace resolution unit test:

```sh
just --justfile .github/actions/get-next-version/justfile unit-test
```

Docker feasibility preflight:

```sh
just --justfile .github/actions/get-next-version/justfile docker-build
just --justfile .github/actions/get-next-version/justfile docker-feasibility-test \
  --major-prefixes breaking,major \
  --minor-prefixes feat,minor \
  --patch-prefixes fix,chore
just --justfile .github/actions/get-next-version/justfile docker-unit-test
```

Default JSON output:

```json
{"currentVersion":"0.14.0","version":"0.14.1","hasNextVersion":"true","bump":"patch"}
```
