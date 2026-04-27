# Execute Terraform & Terragrunt with AWS OIDC

This GitHub Action sets up **Terraform** and **Terragrunt**, authenticates to AWS via **OIDC**, and runs a specified `terragrunt` action: `apply`, `plan`, `apply_plan`, `destroy`, or `init`.

## Features

- Installs pinned versions of Terraform and Terragrunt
- Authenticates to AWS using OIDC only when the selected action actually needs AWS access
- Optionally passes Terragrunt variables via JSON tfvars
- Supports `plan` mode for producing local saved plan files
- Supports `init` mode for outputs-only reads
- Uses the repo-local `./.github/actions/just` action with OIDC for saved plan artifact upload and download
- Exports Terragrunt outputs as compact JSON when state exists

## Inputs

| Name | Description | Required | Default |
|---|---|---|---|
| `tf_version` | Version of Terraform to install | No | `1.13.3` |
| `tg_version` | Version of Terragrunt to install | No | `0.72.6` |
| `aws_region` | AWS region to use | No | `eu-west-2` |
| `override_tg_vars` | Terragrunt variables in JSON, written to `override_tg_vars.tfvars.json` | No | `{}` |
| `aws_oidc_role_arn` | IAM role ARN to assume via OIDC | Yes | — |
| `tg_directory` | Directory containing the Terragrunt config | Yes | — |
| `tg_action` | Terragrunt action: `apply`, `plan`, `apply_plan`, `destroy`, or `init` | Yes | `apply` |

`override_tg_vars` is written for `apply`, `plan`, and `destroy`, but not for `init`.

## Outputs

| Name | Description |
|---|---|
| `tg_outputs` | All Terraform outputs in compact JSON. If no state exists, returns `{}` |
## Behavior

- `apply`
  Runs `terragrunt apply -auto-approve`
- `plan`
  Runs `terragrunt plan -detailed-exitcode -out=<absolute stack path>/terragrunt.tfplan`, then renders `terragrunt.plan.txt` and writes `terragrunt.plan.meta.json` via the repo `justfile.tg` recipe `terragrunt-plan-render`. It then uploads those files to S3 through the repo-local `./.github/actions/just` action using the same OIDC role.
- `apply_plan`
  Downloads the saved plan files into `tg_directory` via the repo-local `./.github/actions/just` action and `justfile.tg`, using the caller-provided `PLAN_ARTIFACT_S3_PREFIX` environment variable plus the stack-derived suffix from `tg_directory`. It then fails if the binary plan file or `terragrunt.plan.meta.json` is missing, reads `has_changes` from the saved metadata file, and skips apply with a GitHub Actions warning when the saved plan contains no mutating resource changes. Otherwise it runs `terragrunt apply` against the absolute stack-path plan file.
- `destroy`
  Runs `terragrunt destroy -auto-approve`
- `init`
  Runs `terragrunt init -input=false -reconfigure` and then captures outputs

## Saved Plan Layout

- One run-level metadata file is stored separately by the shared infra wrapper at:
  - `<plan_artifact_s3_prefix>/infra-plan-metadata/plan-metadata.json`
- Each Terragrunt stack or module stores its own plan bundle at:
  - `<plan_artifact_s3_prefix>/terragrunt-plan-<sanitized-tg-directory>/terragrunt.tfplan`
  - `<plan_artifact_s3_prefix>/terragrunt-plan-<sanitized-tg-directory>/terragrunt.plan.txt`
  - `<plan_artifact_s3_prefix>/terragrunt-plan-<sanitized-tg-directory>/terragrunt.plan.meta.json`

## Usage

### Minimal Apply

```yaml
jobs:
  deploy:
    runs-on: ubuntu-latest
    permissions:
      id-token: write
      contents: read
    steps:
      - uses: actions/checkout@v4

      - name: Apply infrastructure
        id: tg_action
        uses: your-org/your-action-repo@main
        with:
          aws_region: ${{ vars.AWS_REGION }}
          aws_oidc_role_arn: arn:aws:iam::${{ vars.AWS_ACCOUNT_ID }}:role/${{ vars.PROJECT_NAME }}-dev-github-oidc-role
          tg_directory: infra/live/dev/aws/network
          tg_action: apply
          override_tg_vars: '{"env":"dev","region":"eu-west-2"}'

      - name: Use outputs
        run: |
          echo '${{ steps.tg_action.outputs.tg_outputs }}' | jq .
```

### Plan

```yaml
jobs:
  plan:
    runs-on: ubuntu-latest
    permissions:
      id-token: write
      contents: read
    steps:
      - uses: actions/checkout@v4

      - name: Plan infrastructure
        uses: your-org/your-action-repo@main
        with:
          aws_region: ${{ vars.AWS_REGION }}
          aws_oidc_role_arn: arn:aws:iam::${{ vars.AWS_ACCOUNT_ID }}:role/${{ vars.PROJECT_NAME }}-dev-github-oidc-role
          tg_directory: infra/live/dev/aws/network
          tg_action: plan
```

### Apply From Uploaded Plan In S3

```yaml
jobs:
  apply:
    runs-on: ubuntu-latest
    permissions:
      id-token: write
      contents: read
    steps:
      - uses: actions/checkout@v4

      - name: Apply infrastructure from uploaded plan
        uses: your-org/your-action-repo@main
        with:
          aws_region: ${{ vars.AWS_REGION }}
          aws_oidc_role_arn: arn:aws:iam::${{ vars.AWS_ACCOUNT_ID }}:role/${{ vars.PROJECT_NAME }}-dev-github-oidc-role
          tg_directory: infra/live/dev/aws/network
          tg_action: apply_plan
```

This action expects the workflow to download `terragrunt.tfplan`, `terragrunt.plan.txt`, and `terragrunt.plan.meta.json` into `tg_directory` before calling `tg_action: apply_plan`.
