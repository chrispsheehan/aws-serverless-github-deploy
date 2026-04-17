# `migrations`

Lambda wrapper for database migrations using packaged SQLAlchemy models.

## Owns

- migrations Lambda via `_shared/lambda`
- VPC-attached Lambda execution for private Aurora access
- least-scope Secrets Manager read policy for the database credentials object
- explicit 120-second Lambda timeout so schema work and VPC/database startup do not inherit the AWS 3-second default
- packaged SQLAlchemy model metadata copied into the Lambda artifact during the existing Lambda build flow

## Key outputs

- `lambda_function_name`
- `lambda_alias_name`
- `cloudwatch_log_group`

This module is intended for manual or pipeline-triggered schema migrations against the shared Aurora PostgreSQL database. It runs inside the VPC and reuses the shared runtime security group from `security` so it can reach the database without introducing a second database-ingress rule pattern.
The current handler loads the packaged SQLAlchemy models, checks whether its owned table already exists, and creates the declared table metadata directly in the default schema when needed for the worker runtime.
In this repo's reusable code deploy workflow, the function is also invoked automatically when `migrations` is part of the Lambda deployment matrix.
