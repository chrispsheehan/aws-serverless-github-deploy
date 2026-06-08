# Repo-Local Actions

Use this when changing `.github/actions/**`, OIDC role ARN construction, release tagging, or action validation.

## Local Action Ownership

The repo vendors internal GitHub Actions under `.github/actions`, so those workflow `uses:` references point at local paths rather than external action tags.

- [get-changes](../actions/get-changes/README.md) is the repo-local Docker action used by the change-detection path.
- [just](../actions/just/README.md) is the repo-local composite action for installing and running `just`.
- [terragrunt](../actions/terragrunt/README.md) is the repo-local composite action for installing Terraform/Terragrunt and running Terragrunt operations.
- `.github/actions/just` and `.github/actions/terragrunt` assume AWS credentials are already configured in the current job when they need AWS access.
- The repo pattern is to run `aws-actions/configure-aws-credentials` at the top of each AWS-using job, then call local actions without extra auth inputs.

## OIDC Role ARN Contract

Reusable infra, build, deploy, and destroy workflows build `AWS_OIDC_ROLE_ARN` from:

- GitHub variable `AWS_ACCOUNT_ID`
- GitHub variable `PROJECT_NAME`
- workflow environment input such as `ci`, `dev`, or `prod`

Runtime and deploy steps that need a region should read `AWS_REGION` from GitHub variables instead of hardcoding it in workflow YAML.

The role name comes from `infra/root.hcl`:

```hcl
deploy_role_name = "${local.project_name}-${local.environment}-github-oidc-role"
```

Workflow ARN shape:

```text
arn:aws:iam::<AWS_ACCOUNT_ID>:role/<PROJECT_NAME>-<environment>-github-oidc-role
```

For this repo and environment pattern:

- `aws-serverless-github-deploy-ci-github-oidc-role`
- `aws-serverless-github-deploy-dev-github-oidc-role`
- `aws-serverless-github-deploy-prod-github-oidc-role`

If unsure, the live `aws/oidc` stack in the target environment is the source of truth, since Terragrunt passes `deploy_role_name` into the shared OIDC module from `infra/root.hcl`.

## Setup Actions

`./.github/actions/just` installs the requested `just` version through `extractions/setup-crate@v2` in the same minimal composite-action shape as `extractions/setup-just`, rather than depending on `extractions/setup-just` itself.

`./.github/actions/terragrunt` installs Terragrunt through `jdx/mise-action@v4`, while Terraform stays pinned separately through `hashicorp/setup-terraform`.

## Release Tagging Checks

- `release.yml` uses `chrispsheehan/get-release-version`; keep configured commit prefixes aligned with the team's commit convention.
- If allowed PR title prefixes change, update `pull_request.yml` in the same change so the PR gate matches release bump inputs.
- Ensure the release job still reads plain semver tags from repo history in the same format it creates.

## Docker Action Checks

- If a repo-local action uses `runs.using: docker` and needs git state, do not assume a fixed working directory inside the image.
- Resolve checkout from `GITHUB_WORKSPACE` first.
- Otherwise walk up to the nearest `.git` root for local test harnesses.
- Before running git commands against the mounted checkout in GitHub Actions, add that path to git `safe.directory`.
- When changing a repo-local Docker action, prefer adding a PR validation job that executes the action itself so the real GitHub container path is exercised.
