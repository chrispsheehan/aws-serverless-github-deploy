# Execute Terraform & Terragrunt with AWS OIDC

This GitHub Action sets up **Terraform** and **Terragrunt**, authenticates to AWS via **OIDC**, and runs a specified `terragrunt` action: `apply`, `plan`, `apply_plan`, `destroy`, or `init`.

## Features

- Installs pinned versions of Terraform and Terragrunt
- Authenticates to AWS using OIDC only when the selected action actually needs AWS access
- Optionally passes Terragrunt variables via JSON tfvars
- Supports `plan` mode with automatic GitHub artifact upload
- Supports `init` mode for outputs-only reads
- Exports Terragrunt outputs as compact JSON when state exists

## Inputs

| Name | Description | Required | Default |
|---|---|---|---|
| `tf_version` | Version of Terraform to install | No | `1.13.3` |
| `tg_version` | Version of Terragrunt to install | No | `0.72.6` |
| `aws_region` | AWS region to use | No | `eu-west-2` |
| `override_tg_vars` | Terragrunt variables in JSON, written to `override_tg_vars.tfvars.json` | No | `{}` |
| `plan_artifact_run_id` | Optional workflow run ID to download a plan artifact from in `apply_plan` mode | No | `""` |
| `github_token` | GitHub token used for cross-run plan artifact downloads | No | `""` |
| `aws_oidc_role_arn` | IAM role ARN to assume via OIDC | Yes | — |
| `tg_directory` | Directory containing the Terragrunt config | Yes | — |
| `tg_action` | Terragrunt action: `apply`, `plan`, `apply_plan`, `destroy`, or `init` | Yes | `apply` |

`override_tg_vars` is written for `apply`, `plan`, and `destroy`, but not for `init`.

## Outputs

| Name | Description |
|---|---|
| `tg_outputs` | All Terraform outputs in compact JSON. If no state exists, returns `{}` |
| `plan_artifact_name` | Derived GitHub artifact name for a Terragrunt plan |

## Behavior

- `apply`
  Runs `terragrunt apply -auto-approve`
- `plan`
  Runs `terragrunt plan -detailed-exitcode -out=<absolute stack path>/terragrunt.tfplan`, renders a text view to `terragrunt.plan.txt`, writes `terragrunt.plan.meta.json` with `exit_code` and `has_changes`, and uploads all three files as a GitHub artifact. The artifact name is derived from `tg_directory`.
- `apply_plan`
  Downloads the derived plan artifact into the working directory, fails if the artifact, binary plan file, or `terragrunt.plan.meta.json` is missing, reads `has_changes` from the saved metadata file, and skips both AWS authentication and apply with a GitHub Actions warning when the saved plan contains no mutating resource changes. Otherwise it configures AWS credentials and runs `terragrunt apply` against the downloaded absolute stack-path plan file. For separate workflow runs, pass `plan_artifact_run_id` and `github_token`.
- `destroy`
  Runs `terragrunt destroy -auto-approve`
- `init`
  Runs `terragrunt init -input=false -reconfigure` and then captures outputs

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

### Plan And Upload Artifact

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
        id: tg_plan
        uses: your-org/your-action-repo@main
        with:
          aws_region: ${{ vars.AWS_REGION }}
          aws_oidc_role_arn: arn:aws:iam::${{ vars.AWS_ACCOUNT_ID }}:role/${{ vars.PROJECT_NAME }}-dev-github-oidc-role
          tg_directory: infra/live/dev/aws/network
          tg_action: plan

      - name: Show uploaded artifact name
        run: |
          echo "${{ steps.tg_plan.outputs.plan_artifact_name }}"
```

### Apply From Uploaded Plan Artifact

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
