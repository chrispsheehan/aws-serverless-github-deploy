# `_shared/oidc`

Shared GitHub Actions OIDC role module.

## Owns

- the AWS IAM OIDC provider for `token.actions.githubusercontent.com`
- the GitHub Actions IAM role named by `deploy_role_name`
- the attached IAM policy built from `allowed_role_actions`

## Does Not Own

- workflow-level role ARN wiring in GitHub Actions
- downstream AWS permission scoping decisions outside `allowed_role_actions`
- any non-GitHub federated identity provider

## Inputs That Change Behavior

- `deploy_role_name`
- `github_repo`
- `allowed_role_actions`
- `max_session_duration`
- `github_thumbprint`

## Outputs Consumers Rely On

- `oidc_provider_arn`
- `oidc_role`

## Decision Rules

- trust is scoped to the single repository in `github_repo`
- any branch, tag, or environment subject under that repository may assume the role
- runtime permissions are intentionally broad or narrow based on `allowed_role_actions` from the calling stack

## CI / Deploy Expectations

- `ci/aws/oidc` should stay narrowly scoped to artifact-management actions only
- `dev/aws/oidc` and `prod/aws/oidc` may carry the broader deploy scope defined in environment inputs

## Lift / Shift Notes

- this module is vendored into the repo so Terragrunt no longer depends on the external registry module for OIDC role creation
- provider constraints live in this module's own `versions.tf`
