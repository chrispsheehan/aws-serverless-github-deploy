# aws-serverless-github-deploy

## setup roles for ci

```sh
just tg ci aws/oidc apply
just tg dev aws/oidc apply
just tg prod aws/oidc apply
```

## local plan some infra

Given a terragrunt file is found at `infra/live/dev/aws/api/terragrunt.hcl`

```sh
just tg dev aws/api plan
```

## types of lambda deploy

api - canary 50% wait for it to be healthy and then go to 100%

How to use

All at once (fastest):

deploy_strategy = "all_at_once"


Canary 10% for 2 minutes (then 100%):

deploy_strategy        = "canary"
deploy_percentage      = 10
deploy_interval_minutes = 2


Linear 25% every 1 minute:

deploy_strategy        = "linear"
deploy_percentage      = 25
deploy_interval_minutes = 1