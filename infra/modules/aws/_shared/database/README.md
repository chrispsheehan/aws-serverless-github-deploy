# `_shared/database`

Shared Aurora PostgreSQL Serverless v2 module.

## Owns

- Aurora PostgreSQL cluster
- one writer instance and optional reader instances
- database security group
- database subnet group
- SSM parameters for database name, username, password, and endpoints

## Inputs

- `database_name`
- `vpc_id`
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
- `readonly_endpoint_ssm_name`
- `readwrite_endpoint_ssm_name`

This module is intentionally Aurora PostgreSQL Serverless v2 specific. It does not currently support provisioned RDS instances or non-Postgres engines.
