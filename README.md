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

## types of lambda provisioned concurrency

module "lambda_example" {
  source = "../lambda"
  ...
  provisioned_config = var.your_provisioned_config
}

[default] No provisioned lambdas
- use case: background processes
- we can handle an initial lag while lambda warms up/boots
```hcl
provisioned_config = {
    fixed = 0
}
```

[default] X number of provisioned lambdas
- use case: high predictable usage
- we never want lag due to warm up and can predict traffic
```hcl
provisioned_config = {
    fixed = 1
}
```

[default] Scale provisioning when usage exceeds % tolerance 
- use case: react to traffic i.e. api backend
- limit the cost with autoscale.max
- ensure minimal concurrency (no cold starts) with autoscale.min
- set tolerance to amount of used concurrent executions. Below will trigger when 70% are used and add more to meet demands.
- set cool down seconds to reasonable time before you would like the system to react.
```hcl
provisioned_config = {
    auto_scale = {
        max               = 3,
        min               = 1,
        trigger_percent   = 70
        cool_down_seconds = 60
    }
}
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