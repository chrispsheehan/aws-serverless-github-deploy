# `migrations`

Lambda wrapper for database migrations.

## Owns

- migrations Lambda via `_shared/lambda`
- VPC-attached Lambda execution for private Aurora access
- least-scope SSM read policy for the database username and password parameters

## Key outputs

- `lambda_function_name`
- `lambda_alias_name`
- `cloudwatch_log_group`

This module is intended for manual or pipeline-triggered schema migrations against the shared Aurora PostgreSQL database. It runs inside the VPC and reuses the shared runtime security group from `security` so it can reach the database without introducing a second database-ingress rule pattern.
