# aws-serverless-github-deploy

**Terraform + GitHub Actions for AWS serverless deployments.**  
Lambda + ECS with CodeDeploy rollouts, plus provisioned concurrency controls for Lambda — driven by clean module variables and `just` recipes.

---

## 🚀 setup roles for ci

```sh
just tg ci aws/oidc apply
just tg dev aws/oidc apply
just tg prod aws/oidc apply
```

## 🧱 prerequisite network

The AWS account must already have the landing-zone or StackSet network in place before deploying this repo.

- the Terraform in this repo reads the VPC and subnets with `data` sources rather than creating them
- the expected VPC and subnets must therefore already exist
- the private subnets must be tagged so the module lookups can find them, for example with names matching `*private*`

If those shared network resources do not exist yet, the infra applies in this repo will fail during data lookup.

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
    fixed                = 0
    reserved_concurrency = 2 # only allow 2 concurrent executions THIS ALSO SERVES AS A LIMIT TO AVOID THROTTLING
}
```

#### 🔒 X number of provisioned lambdas
- use case: high predictable usage
- we never want lag due to warm up and can predict traffic
```hcl
provisioned_config = {
    fixed                = 10
    reserved_concurrency = 50
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
- before scaling the lambda alias will match the minmum value
![a](docs/lambda-config-before.png)
- when the trigger percent is exceeded the lambda moves into `In progress (1/2)` state as an additional provisioned lambda is added.
![a](docs/lamba-scaling-up.png)
- after scaling the lambda alias will show an additional provisioned lambda
![a](docs/lambda-config-after.png)


## 🚦 types of lambda deploy

```hcl
module "lambda_example" {
  source = "../_shared/lambda"
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
    strategy         = "canary"
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
```

## 🚦 types of ecs deploy

```hcl
module "service_example" {
  source = "../_shared/service"
  ...
  deployment_strategy = var.your_deployment_strategy
}
```

#### ⚡ [default] All at once:

- use case: internal services, queue workers, low-risk changes
- still uses ECS CodeDeploy, but shifts traffic in one step
```hcl
deployment_strategy = "all_at_once"
```

#### 🐤 canary deployment:

- use case: HTTP services behind the load balancer
- shifts 10% of traffic for 5 minutes before moving to 100%
```hcl
deployment_strategy = "canary"
```

#### 📶 linear deployment:

- use case: steady rollout with smaller blast radius
- shifts traffic 10% every minute until complete
```hcl
deployment_strategy = "linear"
```

#### 🟦🟩 blue/green deployment:

- use case: explicit blue/green semantics while still using the default ECS all-at-once traffic switch
- currently maps to the ECS CodeDeploy all-at-once config
```hcl
deployment_strategy = "blue_green"
```

- ECS CodeDeploy is only created for load-balanced ECS services in `_shared/service`
- the deployment workflow:
  - applies the new `task_*` revision
  - reads `codedeploy_app_name` and `codedeploy_deployment_group_name` from `service_*`
  - renders [`appspec-ecs.yml`](appspec-ecs.yml)
  - uploads the AppSpec to the code bucket
  - runs `just ecs-deploy`

## 🔥↩️ deployment roll-back

- use cloudwatch metrics and alarms to automatically roll-back a deployment
- create a [cloudwatch_metric_alarm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) resource and pass in as per below

```hcl
module "lambda_example" {
  source = "../_shared/lambda"
  ...
  codedeploy_alarm_names = [
    local.api_5xx_alarm_name
  ]
}
```
- the ECS shared service module accepts the same `codedeploy_alarm_names` input
- if the alarm triggers during a deployment you will see the below in the CI

```
📦 Running: lambda-deploy
🚀 Deployment started: d-40UUQH3DF
Attempt 1: Deployment status is InProgress
Attempt 2: Deployment status is InProgress
Attempt 3: Deployment status is InProgress
Attempt 4: Deployment status is InProgress
Attempt 5: Deployment status is Stopped
❌ Deployment d-40UUQH3DF failed or was stopped.
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
|                                                                                                                    GetDeployment                                                                                                                    |
+--------------+--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
|  ErrorCode   |  ALARM_ACTIVE                                                                                                                                                                                                                        |
|  ErrorMessage|  One or more alarms have been activated according to the Amazon CloudWatch metrics you selected, and the affected deployments have been stopped. Activated alarms: <dev-aws-serverless-github-deploy-api-api-v2-5xx-rate-critical>   |
|  Status      |  Stopped                                                                                                                                                                                                                             |
+--------------+--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
error: Recipe `lambda-deploy` failed with exit code 1
Error: Process completed with exit code 1.

```

## 🚢 deployment strategies

- Infrastructure and feature code deployments (via codedeploy) are completely decoupled.
- Initial infrastructure deployments deploys `infra/modules/aws/_shared/lambda/bootstrap/index.py` which serves as a place-holder.
- Initial ECS infrastructure deployments can use a bootstrap task, while the deploy workflow later registers a real `task_*` revision and promotes it via CodeDeploy.
- The code deploy app and group are also deployed, which is the mechanism used to deploy the real builds.
- Subsequent re-runs of the infrastructure deployments will not update the code.
