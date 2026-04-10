# `_shared/lambda`

Shared Lambda module with versioned deploys through CodeDeploy.

## Owns

- Lambda function
- alias and published versions
- optional provisioned concurrency
- Lambda CodeDeploy app and deployment group
- bootstrap zip used for initial infra applies

## Key inputs

- `deployment_config`
- `provisioned_config`
- `codedeploy_alarm_names`
- `code_bucket`

## Key outputs

- function name and ARN
- alias name and ARN
- log group

Use this when you want Lambda infra and Lambda rollout behavior managed together.
