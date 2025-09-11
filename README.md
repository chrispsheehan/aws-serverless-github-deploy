# aws-serverless-github-deploy

**Terraform + GitHub Actions for AWS serverless deployments.**  
Lambda + API Gateway with CodeDeploy rollouts and provisioned concurrency controls — driven by clean module variables and `just` recipes.

---

## 🚀 setup roles for ci

```sh
just tg ci aws/oidc apply
just tg dev aws/oidc apply
just tg prod aws/oidc apply
```

## 🛠️ local plan some infra

Given a terragrunt file is found at `infra/live/dev/aws/api/terragrunt.hcl`

```sh
just tg dev aws/api plan
```

## ⚙️ types of lambda provisioned concurrency

```hcl
module "lambda_example" {
  source = "../lambda"
  ...
  provisioned_config = var.your_provisioned_config
}
```

#### ✅ [default] No provisioned lambdas
- use case: background processes
- we can handle an initial lag while lambda warms up/boots
```hcl
provisioned_config = {
    fixed = 0
}
```

#### 🔒 X number of provisioned lambdas
- use case: high predictable usage
- we never want lag due to warm up and can predict traffic
```hcl
provisioned_config = {
    fixed = 1
}
```

#### 📈 Scale provisioning when usage exceeds % tolerance 
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

## 🚦 types of lambda deploy

```hcl
module "lambda_example" {
  source = "../lambda"
  ...
  deployment_config = var.your_deployment_config
}
```

#### ⚡ [default] All at once (fastest):

- use case: background processes
```hcl
deployment_config = {
    strategy = "all_at_once"
}
```

#### 🐤 canary deployment:

- use case: api or service serving traffic
- incrementally rolls out new version to 10% of lambdas and rolls back if errors detected. If not goes to 100%.
- waits to make a decision on health after 1 minute
```hcl
deployment_config = {
    strategy         = "linear"
    percentage       = 10
    interval_minutes = 1
}
```

#### 📶 linear deployment:

- use case: api or service serving traffic
- checks for lambda health on 10% of lambdas and rolls back if errors detected
- rolls out changes on increments of 1 minute
```hcl
deployment_config = {
    strategy         = "linear"
    percentage       = 10
    interval_minutes = 1
}
