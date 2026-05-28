# `migrations`

Database migration runtime for the local and AWS-backed PostgreSQL paths.

## Owns

- creating the `worker_messages` table when it does not exist
- idempotent startup checks for the migration-managed tables
- additive schema updates for the `worker_messages` verification columns used by the local ECS worker debug path

## Does Not Own

- long-lived database connectivity
- application message processing
- Terraform or deployment orchestration

## Runtime Notes

- `run_migration()` is the shared entrypoint for the migration behavior
- `lambda_handler()` wraps that function for AWS Lambda
- the local Docker image runs `run_migration()` once on startup and then reruns it when Python files under `lambdas/migrations/` change
- the migration is intentionally idempotent and reports a skipped result when the target table already exists

## Invoke In AWS

After the infra stack and Lambda code are deployed, invoke the migration Lambda with:

```sh
AWS_REGION=eu-west-2 \
LAMBDA_NAME=dev-aws-serverless-github-deploy-migrations \
just --justfile justfile.deploy lambda-invoke
```

In this repo's reusable code deploy workflow, the function is also invoked automatically when `migrations` is part of the Lambda deployment matrix.
