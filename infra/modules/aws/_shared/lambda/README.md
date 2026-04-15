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
- optional `vpc_subnet_ids` and `vpc_security_group_ids` when the Lambda must run inside private subnets

When VPC attachment is enabled, the module creates and attaches its own Lambda VPC access policy covering the EC2 network-interface permissions needed for private-subnet execution.

## Key outputs

- function name and ARN
- alias name and ARN
- log group

Use this when you want Lambda infra and Lambda rollout behavior managed together.
