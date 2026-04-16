# Execute Terraform & Terragrunt with AWS OIDC

This GitHub Action sets up **Terraform** and **Terragrunt**, authenticates to AWS via **OIDC**, and runs a specified `terragrunt` action — `apply`, `destroy`, or **`init` (outputs-only)** — with optional override variables.

---

## 🚀 Features

- Installs pinned versions of **Terraform** and **Terragrunt**
- Authenticates to AWS using **OIDC** (no static keys)
- Optionally passes Terragrunt variables via **JSON tfvars**
- Supports an **outputs-only** mode (`tg_action: init`) that safely runs `terragrunt init` and then exports **all Terraform outputs**
- Emits CI-friendly logs with `TF_IN_AUTOMATION=true`

---

## 📥 Inputs

| Name                | Description                                                                 | Required | Default     |
|---------------------|-----------------------------------------------------------------------------|----------|-------------|
| `tf_version`        | Version of Terraform to install                                             | ❌        | `1.10.5`    |
| `tg_version`        | Version of Terragrunt to install                                            | ❌        | `0.72.6`    |
| `aws_region`        | AWS region to use                                                           | ❌        | `eu-west-2` |
| `override_tg_vars`  | Terragrunt variables in **JSON** (written to `override_tg_vars.tfvars.json`) | ❌        | `{}`        |
| `aws_oidc_role_arn` | IAM Role ARN to assume via OIDC                                             | ✅        | —           |
| `tg_directory`      | Directory containing your Terragrunt config                                  | ✅        | —           |
| `tg_action`         | Terragrunt action: **`apply`**, **`destroy`**, or **`init` (outputs-only)**  | ✅        | `apply`     |

> ℹ️ The `override_tg_vars` file is created **only** for `apply`/`destroy` (not for `init`).

---

## 📤 Outputs

| Name         | Description                                                                 |
|--------------|-----------------------------------------------------------------------------|
| `tg_outputs` | All Terraform outputs in **compact JSON**. If no state exists, returns `{}` |

---

## 🛠 Usage

### Minimal (Apply)
```yaml
jobs:
  deploy:
    runs-on: ubuntu-latest
    permissions:
      id-token: write   # required for OIDC
      contents: read

    steps:
      - uses: actions/checkout@v4

      - name: Deploy Infrastructure
        id: tg_action
        uses: your-org/your-action-repo@main
        with:
          tf_version: "1.10.5"
          tg_version: "0.72.6"
          aws_region: eu-west-2
          aws_oidc_role_arn: arn:aws:iam::<ACCOUNT_ID>:role/<github-oidc-role>
          tg_directory: ./infra/dev
          tg_action: apply
          override_tg_vars: '{"env":"dev","region":"eu-west-2"}'

      - name: Use outputs
        run: |
          echo '${{ steps.tg_action.outputs.tg_outputs }}' | jq .
