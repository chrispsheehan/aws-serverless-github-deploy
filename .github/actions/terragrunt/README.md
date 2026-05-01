# Execute Terraform & Terragrunt

This GitHub Action sets up **Terraform** and **Terragrunt** and runs a specified `terragrunt` action: `apply`, `plan`, `apply_plan`, `destroy`, or `init`. When the action needs AWS, the workflow job should configure credentials first.

## Features

- Installs pinned versions of Terraform and Terragrunt
- Installs Terragrunt through `jdx/mise-action@v4`
- Uses AWS credentials already configured earlier in the same job when needed
- Optionally passes Terragrunt variables via JSON tfvars
- Supports `plan` mode for producing local saved plan files
- Supports `init` mode for outputs-only reads
- Uses the repo-local `./.github/actions/just` action for saved plan artifact upload and download
- Exports Terragrunt outputs as compact JSON when state exists

## Inputs

| Name | Description | Required | Default |
|---|---|---|---|
| `tf_version` | Version of Terraform to install | No | `1.13.3` |
| `tg_version` | Version of Terragrunt to install | No | `0.72.6` |
| `aws_region` | AWS region to use | No | `eu-west-2` |
| `override_tg_vars` | Terragrunt variables in JSON, written to `override_tg_vars.tfvars.json` | No | `{}` |
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
  Runs `terragrunt plan -detailed-exitcode -out=<absolute stack path>/terragrunt.tfplan`, then renders `terragrunt.plan.txt` and writes `terragrunt.plan.meta.json` via the repo `justfile.tg` recipe `terragrunt-plan-render`. It then uploads those files to S3 through the repo-local `./.github/actions/just` action using the AWS credentials already configured in the job.
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

## AWS Credentials

Configure AWS credentials in the workflow job before calling this action. The action then reuses those ambient credentials for Terragrunt itself and for any saved-plan upload or download steps.

## Usage

### Reuse AWS credentials already configured in the job

```yaml
jobs:
  deploy:
    runs-on: ubuntu-latest
    permissions:
      id-token: write
      contents: read
    steps:
      - uses: actions/checkout@v4

      - name: Configure AWS credentials once
        uses: aws-actions/configure-aws-credentials@v6
        with:
          aws-region: ${{ vars.AWS_REGION }}
          role-to-assume: ${{ env.AWS_OIDC_ROLE_ARN }}

      - name: Reuse ambient session in Terragrunt
        uses: ./.github/actions/terragrunt
        with:
          tg_directory: infra/live/dev/aws/network
          tg_action: init
```

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

      - name: Configure AWS credentials once
        uses: aws-actions/configure-aws-credentials@v6
        with:
          aws-region: ${{ vars.AWS_REGION }}
          role-to-assume: arn:aws:iam::${{ vars.AWS_ACCOUNT_ID }}:role/${{ vars.PROJECT_NAME }}-dev-github-oidc-role

      - name: Plan infrastructure
        uses: your-org/your-action-repo@main
        with:
          aws_region: ${{ vars.AWS_REGION }}
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

      - name: Configure AWS credentials once
        uses: aws-actions/configure-aws-credentials@v6
        with:
          aws-region: ${{ vars.AWS_REGION }}
          role-to-assume: arn:aws:iam::${{ vars.AWS_ACCOUNT_ID }}:role/${{ vars.PROJECT_NAME }}-dev-github-oidc-role

      - name: Apply infrastructure from uploaded plan
        uses: your-org/your-action-repo@main
        with:
          aws_region: ${{ vars.AWS_REGION }}
          tg_directory: infra/live/dev/aws/network
          tg_action: apply_plan
```

This action expects the workflow to download `terragrunt.tfplan`, `terragrunt.plan.txt`, and `terragrunt.plan.meta.json` into `tg_directory` before calling `tg_action: apply_plan`.
