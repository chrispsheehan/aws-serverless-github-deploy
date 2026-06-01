# `lambdas`

Lambda source directories for this boilerplate.

## Structure

- `deploy.yml` is the Lambda build/deploy manifest
- each entry in `deploy.yml` maps a Lambda source directory to a live Terragrunt stack path template
- the generated `lambdas/build` directory is build output only and is intentionally excluded from Lambda discovery
- `lambdas/lib/` contains Lambda-only helper modules and is intentionally excluded from Lambda discovery
- a deployable Lambda also needs the live Terragrunt stack declared by its manifest `stack` value

## Common Shape

- `<lambda_name>/lambda_handler.py`
- `<lambda_name>/requirements.txt`
- optional `<lambda_name>/README.md` for the Lambda's application logic and operational notes
- optional supporting packages such as `database_models/`

## Build Behavior

- Lambda discovery reads `lambdas/deploy.yml`
- `stack` is a repo-relative Terragrunt stack path template and must use `{environment}` for the environment segment, for example `infra/live/{environment}/aws/lambda_api`
- `source_dir` is the repo-relative source directory to package, for example `lambdas/lambda_api`
- the zip artifact name is computed from `basename(source_dir)`, so `lambdas/lambda_api` publishes `lambdas/<version>/lambda_api.zip`
- build workflows deduplicate by `source_dir`; deploy workflows keep every manifest entry so the same source can roll out to multiple Lambda stacks
- wrapper workflows do not pass Lambda matrices; update this manifest to add, remove, or remap deployed Lambdas
- `after_deploy: invoke` can be set on a manifest entry when the deployed Lambda should be invoked after CodeDeploy completes
- the Lambda build flow installs `requirements.txt` into a per-Lambda build directory
- it copies Python source files, shared helpers from `lib/` and `lambdas/lib/`, and supported package directories into the zip artifact
- markdown files in Lambda source trees are documentation only and are pruned before the zip artifact is created
- manifest detection alone is not enough: the runtime still needs the declared Terragrunt stack to participate in infra apply and code rollout correctly

## Boilerplate Patterns

- request-serving Lambdas can plug into the shared API surface through the Lambda module family
- worker Lambdas can consume shared queue infrastructure
- the `migrations` Lambda shape is intended for VPC-attached schema changes against the shared database
- event-driven helper Lambdas can subscribe to EventBridge rules for shared infra automation, such as reacting to Aurora reader scale-out events

## Local Runtime

- local Lambda services run through the reusable harnesses under `local/`
- `lambda_api` is exposed at `http://localhost:18080`
- `lambda_worker` polls the local `lambda-worker-queue`
- `watchfiles` restarts local Lambda services when Python files change

Concrete runtime notes:

- API publish contract: [lambda_api/README.md](lambda_api/README.md)
- worker queue publishing: [lambda_worker/README.md](lambda_worker/README.md)

## Logging

- Lambda runtimes should use the shared JSON logger from `lib/runtime_logging.py`
- logs are written to stdout so they appear in the function's CloudWatch log group
- prefer structured fields via logger `extra={...}` rather than ad-hoc string interpolation

## Runtime Documentation

- add a `README.md` inside a concrete Lambda directory when the function has non-trivial business logic
- use that README to explain what the Lambda does, the event shape it expects, important downstream integrations, and any operational or failure-mode notes

## Related Docs

- deployment and rollout rules: [infra/modules/aws/_shared/lambda/README.md](../infra/modules/aws/_shared/lambda/README.md)
- shared infra context: [infra/README.md](../infra/README.md)
