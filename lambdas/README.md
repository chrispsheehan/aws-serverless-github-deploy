# `lambdas`

Lambda source directories for this boilerplate.

## Structure

- each top-level directory under `lambdas/` is treated as a deployable Lambda
- the generated `lambdas/build` directory is build output only and is intentionally excluded from Lambda discovery
- a deployable Lambda also needs a corresponding live Terragrunt stack under `infra/live/<environment>/aws/<lambda_name>/terragrunt.hcl`

## Common Shape

- `<lambda_name>/lambda_handler.py`
- `<lambda_name>/requirements.txt`
- optional `<lambda_name>/README.md` for the Lambda's application logic and operational notes
- optional supporting packages such as `database_models/`

## Build Behavior

- Lambda directory discovery auto-detects top-level directories under `lambdas/` for build and deploy workflows
- the Lambda build flow installs `requirements.txt` into a per-Lambda build directory
- it copies Python source files and supported package directories into the zip artifact
- markdown files in Lambda source trees are documentation only and are pruned before the zip artifact is created
- detection alone is not enough: the runtime still needs the matching Terragrunt stack to participate in infra apply and code rollout correctly

## Boilerplate Patterns

- request-serving Lambdas can plug into the shared API surface through the Lambda module family
- worker Lambdas can consume shared queue infrastructure
- the `migrations` Lambda shape is intended for VPC-attached schema changes against the shared database

## Runtime Documentation

- add a `README.md` inside a concrete Lambda directory when the function has non-trivial business logic
- use that README to explain what the Lambda does, the event shape it expects, important downstream integrations, and any operational or failure-mode notes

## Related Docs

- deployment and rollout rules: [infra/modules/aws/_shared/lambda/README.md](../infra/modules/aws/_shared/lambda/README.md)
- shared infra context: [infra/README.md](../infra/README.md)
