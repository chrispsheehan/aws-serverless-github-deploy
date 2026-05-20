# Execute Terraform & Terragrunt

This GitHub Action sets up **Terraform** and **Terragrunt** and runs a specified `terragrunt` action: `apply`, `plan`, `apply_plan`, `destroy`, `init`, or `graph`. When the action needs AWS, the workflow job should configure credentials first.

## Features

- Installs pinned versions of Terraform and Terragrunt
- Installs Terragrunt through `jdx/mise-action@v4`
- Uses AWS credentials already configured earlier in the same job when needed
- Optionally passes Terragrunt variables via JSON tfvars
- Supports `plan` mode for producing local saved plan files
- Supports `init` mode for outputs-only reads
- Supports `graph` mode for `terragrunt run-all graph-dependencies` rendered as Graphviz JSON
- Relies on shared Terragrunt root hooks for per-stack saved plan artifact upload and download
- Exports Terragrunt outputs as compact JSON when state exists

The Terragrunt install step is kept in this repo-local action rather than hidden behind a third-party Terragrunt wrapper action so the repo can control the exact setup-action revision and react quickly to GitHub Actions runtime deprecations or nested dependency warnings.

## Inputs

| Name | Description | Required | Default |
|---|---|---|---|
| `tf_version` | Version of Terraform to install | No | `1.13.3` |
| `tg_version` | Version of Terragrunt to install | No | `0.72.6` |
| `aws_region` | AWS region to use | No | `eu-west-2` |
| `override_tg_vars` | Terragrunt variables in JSON, written to `override_tg_vars.tfvars.json` | No | `{}` |
| `tg_directory` | Directory containing the Terragrunt config | Yes | — |
| `tg_action` | Terragrunt action: `apply`, `plan`, `apply_plan`, `destroy`, `init`, or `graph` | Yes | `apply` |

`override_tg_vars` is written for `apply`, `plan`, and `destroy`, but not for `init`.

## Outputs

| Name | Description |
|---|---|
| `tg_outputs` | All Terraform outputs in compact JSON. If no state exists, returns `{}` |
| `tg_graph_json` | Terragrunt `run-all graph-dependencies` rendered as compact Graphviz JSON. Set only for `tg_action: graph` |
## Behavior

- `apply`
  Runs `terragrunt apply -auto-approve`
- `plan`
  Runs `terragrunt plan -detailed-exitcode -out=terragrunt.tfplan`. The shared Terragrunt root `after_hook` renders `terragrunt.plan.txt`, writes `terragrunt.plan.meta.json`, always uploads the metadata, and only uploads `terragrunt.tfplan` plus `terragrunt.plan.txt` when the metadata says the stack has changes.
- `apply_plan`
  Runs `terragrunt apply terragrunt.tfplan`. The shared Terragrunt root `before_hook` downloads the saved plan bundle into the Terragrunt working directory when `TG_ENABLE_PLAN_ARTIFACTS=true` and `PLAN_ARTIFACT_RUN_ID` is set, and fails early if the saved metadata reports mocked dependency outputs.
- `destroy`
  Runs `terragrunt destroy -auto-approve`
- `init`
  Runs `terragrunt init -input=false -reconfigure` and then captures outputs
- `graph`
  Installs Graphviz in the action, runs `terragrunt run-all graph-dependencies --terragrunt-non-interactive --terragrunt-include-external-dependencies | dot -Tjson`, and exposes the compact JSON as `tg_graph_json`

## Saved Plan Layout

- One run-level metadata file is stored separately by the shared infra wrapper as a GitHub Actions artifact:
  - artifact name: `infra-plan-metadata`
  - file: `plan-metadata.json`
- Each Terragrunt stack or module stores its own plan bundle at:
  - `s3://<plan_bucket>/terragrunt_plan/<environment>/<plan_run_id>/terragrunt-plan-<sanitized-tg-directory>/terragrunt.plan.meta.json`
  - `s3://<plan_bucket>/terragrunt_plan/<environment>/<plan_run_id>/terragrunt-plan-<sanitized-tg-directory>/terragrunt.tfplan` only when changes exist
  - `s3://<plan_bucket>/terragrunt_plan/<environment>/<plan_run_id>/terragrunt-plan-<sanitized-tg-directory>/terragrunt.plan.txt` only when changes exist

## AWS Credentials

Configure AWS credentials in the workflow job before calling this action. The action then reuses those ambient credentials for Terragrunt itself and for any Terragrunt-hook-driven saved-plan upload or download steps.

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

This action expects the workflow to set both `TG_ENABLE_PLAN_ARTIFACTS=true` and `PLAN_ARTIFACT_RUN_ID` when using cross-run saved plans so the shared Terragrunt root hooks can resolve the per-stack plan bundle location from the derived plan bucket and environment.
