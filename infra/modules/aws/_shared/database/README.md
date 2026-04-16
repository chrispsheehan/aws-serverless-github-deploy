# `_shared/database`

Shared Aurora PostgreSQL Serverless v2 module.

## Owns

- Aurora PostgreSQL cluster
- one writer instance and optional reader instances
- database subnet group
- SSM parameters for database name and endpoints
- the Aurora-managed Secrets Manager master credentials object for the database username and password
- a generated master username that always starts with a letter so Aurora accepts it reliably

## Depends on

- subnet ids passed in by the caller
- a PostgreSQL security group passed in by the caller, typically from the `security` stack

## Inputs

- `database_name`
- `subnet_ids`
- `database_security_group_id`
- `publicly_accessible`
- `database_port`
- `engine_version`
- `backup_retention_period`
- `rds_min_capacity`
- `rds_max_capacity`
- `rds_max_reader_count`

## Key outputs

- `cluster_identifier`
- `security_group_id`
- `credentials_secret_arn`
- `readonly_endpoint_ssm_name`
- `readwrite_endpoint_ssm_name`
- `database_name`
- `database_port`
- `readonly_endpoint`
- `readwrite_endpoint`

This module is intentionally Aurora PostgreSQL Serverless v2 specific. It does not currently support provisioned RDS instances or non-Postgres engines.
In this repo the concrete `database` wrapper resolves the VPC and public or private subnet ids, while the shared infra workflow injects `database_security_group_id` from the `security` stack via `TF_VAR_database_security_group_id`.
By default the module tracks the latest matching Aurora PostgreSQL 16.x engine version rather than pinning a specific patch release.
SSM parameter paths are rooted at `/<environment>/<project>/<database>/...` so they do not collide with AWS-reserved `/aws` prefixes.
The runtime contract for database credentials is the Aurora-managed master secret exposed from the cluster. Terraform reads the managed secret ARN directly from the cluster resource rather than doing a separate Secrets Manager lookup during the same apply, because AWS may not populate that managed-secret reference early enough for an immediate data read.
