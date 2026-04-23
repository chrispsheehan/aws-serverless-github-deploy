# `_shared/oidc`

Shared GitHub Actions OIDC role module.

This repo vendors the module locally so the live `aws/oidc` stacks do not depend on an external Terraform Registry source.

## Owns

- IAM role for GitHub Actions OIDC assumption
- attached IAM policies for state access, repo-defined AWS access, and optional role-management access
- lookup of the existing GitHub Actions OIDC provider in the target AWS account

## Does Not Own

- creation of the GitHub OIDC provider itself
- workflow-level `configure-aws-credentials` usage
- repo-specific decisions about how broad `ci`, `dev`, or `prod` access should be

## Requirements

- the AWS account must already contain the IAM OIDC provider for `https://token.actions.githubusercontent.com`
- the Terragrunt caller must provide the state bucket and DynamoDB lock table names
- caller policy scope is controlled by `allowed_role_actions` and `allowed_role_resources`

## Repo Contract

The live stacks are:

- `infra/live/ci/aws/oidc`
- `infra/live/dev/aws/oidc`
- `infra/live/prod/aws/oidc`

Apply them with:

```sh
just tg ci aws/oidc apply
just tg dev aws/oidc apply
just tg prod aws/oidc apply
```

Role scope in this repo:

- `ci`
  intentionally narrow; used for shared artifact management, current CI IAM interactions, and ECR image publishing
- `dev` and `prod`
  broader deploy roles; include the database, Cognito, certificate, and Route53 access needed by the repo's runtime stacks

The `ci` role is not the repo's general deploy role. If a workflow needs deploy permissions, treat that as a contract change and document the exact additional AWS actions.

## Inputs That Change Behavior

- `deploy_role_name`
- `github_repo`
- `deploy_branches`
- `deploy_tags`
- `deploy_environments`
- `allow_deployments`
- `allowed_role_actions`
- `allowed_role_resources`
- `state_bucket`
- `state_lock_table`

## Outputs Consumers Rely On

- role ARN

Used by GitHub Actions via `aws-actions/configure-aws-credentials`.
