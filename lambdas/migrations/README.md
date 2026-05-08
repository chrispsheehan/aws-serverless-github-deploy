# `migrations`

Database migration runtime for the local and AWS-backed PostgreSQL paths.

## Owns

- creating the `worker_messages` table when it does not exist
- idempotent startup checks for the migration-managed tables

## Does Not Own

- long-lived database connectivity
- application message processing
- Terraform or deployment orchestration

## Runtime Notes

- `run_migration()` is the shared entrypoint for the migration behavior
- `lambda_handler()` wraps that function for AWS Lambda
- the local Docker image imports and executes `run_migration()` directly from its container `CMD`
- the migration is intentionally idempotent and reports a skipped result when the target table already exists
