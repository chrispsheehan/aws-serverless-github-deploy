# `_shared/database`

Shared Aurora PostgreSQL Serverless v2 module.

## Owns

- Aurora PostgreSQL cluster
- one writer instance and optional reader instances
- database subnet group
- SSM parameters for database name, username, password, and endpoints

## Depends on

- a PostgreSQL security group passed in by the caller, typically from the `security` stack

## Inputs

- `database_name`
- `database_security_group_id`
- `vpc_name`
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
- `username_ssm_name`
- `password_ssm_name`
- `username_ssm_arn`
- `password_ssm_arn`
- `readonly_endpoint_ssm_name`
- `readwrite_endpoint_ssm_name`
- `database_name`
- `database_port`
- `readonly_endpoint`
- `readwrite_endpoint`

This module is intentionally Aurora PostgreSQL Serverless v2 specific. It does not currently support provisioned RDS instances or non-Postgres engines.
In this repo the shared infra workflow injects `database_security_group_id` from the `security` stack via `TF_VAR_database_security_group_id`.
By default the module tracks the latest matching Aurora PostgreSQL 16.x engine version rather than pinning a specific patch release.
