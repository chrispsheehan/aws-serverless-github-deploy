# `migrations`

Lambda wrapper for database migrations using `pgroll`.

## Owns

- migrations Lambda via `_shared/lambda`
- VPC-attached Lambda execution for private Aurora access
- least-scope Secrets Manager read policy for the database credentials object
- explicit 120-second Lambda timeout so schema work and VPC/database startup do not inherit the AWS 3-second default
- pinned `pgroll` Linux binary packaged into the Lambda artifact during the existing Lambda build flow

## Key outputs

- `lambda_function_name`
- `lambda_alias_name`
- `cloudwatch_log_group`

This module is intended for manual or pipeline-triggered schema migrations against the shared Aurora PostgreSQL database. It runs inside the VPC and reuses the shared runtime security group from `security` so it can reach the database without introducing a second database-ingress rule pattern.
The current handler uses `pgroll init`, applies a baseline on first use when the database already contains public tables, then runs the packaged migration file and completes it so the resulting table is available in the default schema for the existing worker runtime.
In this repo's reusable code deploy workflow, the function is also invoked automatically when `migrations` is part of the Lambda deployment matrix.
