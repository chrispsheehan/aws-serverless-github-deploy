# Changing And Deploying Safely

This repo separates infrastructure changes from feature-code rollouts. Treat that split as the default working model.

## Before Changing Anything

- Read the nearest owning README before editing code, Terraform, Terragrunt, workflows, or runtime behavior.
- Keep changes narrow: one infrastructure concern, runtime, workflow contract, or deployment path per PR when possible.
- Update docs in the same PR when behavior, commands, module inputs/outputs, workflow contracts, bootstrap order, or operator actions change.
- Prefer focused validation over broad run-all commands. Name any validation you could not run and why.

## Safe Infrastructure Changes

Use infrastructure workflows for Terraform/Terragrunt shape changes only. Applying infra should create or update the stable deploy surface; it should not be the mechanism that rolls out new feature code.

Recommended flow:

1. Make the smallest module/live-stack change that owns the behavior.
2. Check dependency edges and mock outputs if a stack consumes another stack through Terragrunt `dependency`.
3. Run the smallest relevant local plan or validate when feasible, for example:

```sh
just tg dev aws/lambda_api plan
just tg dev aws/service_api plan
```

4. For workflow-managed environments, prefer saved-plan review before apply:
   - `dev_infra_plan.yml`
   - `dev_infra_apply_from_plan.yml`
   - `prod_infra_plan.yml`
   - `prod_infra_apply_from_plan.yml`
5. Use no-plan applies only when the change is low risk or already reviewed through another path:
   - `dev_infra_apply_no_plan.yml`
   - `prod_infra_apply_no_plan.yml`

Saved plans are apply-intent artifacts. Do not reuse a saved plan if upstream real outputs have changed, if it captured mock outputs, or if artifact retention may have expired.

## Deploying Code Without Changing Infra

Use code deploy workflows for Lambda zips, ECS task images, and frontend assets. These workflows publish artifacts and roll them into infrastructure that already exists.

- Dev code deploy: `dev_code_deploy.yml`
- Prod code deploy: `prod_code_deploy.yml`
- Release build and publish: `release.yml`

For an individual runtime, deploy only the relevant artifact/version where the workflow input supports it. Typical targets are:

- Lambda function code under `lambdas/<name>`
- ECS service images under `containers/<name>`
- frontend assets under `frontend`

Do not bundle unrelated infra changes into a code-only deploy. If a code change needs a new environment variable, IAM permission, route, queue, table, database object, or service shape, apply the infra change first, then deploy code.

## Runtime-Specific Checks

- Lambda changes: confirm the matching live stack exists and the Lambda deploy matrix will include the function.
- ECS changes: confirm the `containers/<name>` directory has matching `task_<name>` and `service_<name>` live stacks when it is a service runtime.
- Frontend changes: confirm the frontend artifact is published before deploying assets to the live bucket and invalidating CloudFront.
- Migration changes: keep migration invocation explicit; do not rely on unrelated runtime deploys to imply database changes.

## PR Expectations

PRs should make the rollout path obvious:

- state whether the change is infra, code deploy, docs-only, or a combination
- list the exact local commands or workflows used for validation
- call out any skipped plan, skipped deploy, missing AWS access, or manual follow-up
- include docs updates for changed operator behavior

The workflow docs own deeper CI contract detail:

- entrypoints: [.github/docs/workflow-entrypoints.md](.github/docs/workflow-entrypoints.md)
- saved plans: [.github/docs/artifacts-and-plans.md](.github/docs/artifacts-and-plans.md)
- discovery and matrices: [.github/docs/discovery-and-matrices.md](.github/docs/discovery-and-matrices.md)
- reusable workflow contracts: [.github/docs/reusable-workflows.md](.github/docs/reusable-workflows.md)
