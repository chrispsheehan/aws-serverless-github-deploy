# `database`

Concrete Aurora PostgreSQL wrapper.

## Owns

- repo-specific VPC and subnet discovery for the database stack
- the shared Aurora PostgreSQL Serverless v2 module via `_shared/database`

## Depends on

- a pre-existing tagged VPC and tagged public or private subnets
- a PostgreSQL security group passed in by the caller, typically from the `security` stack

## Inputs

- `database_name`
- `vpc_name`
- `publicly_accessible`
- `database_security_group_id`
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

This module keeps repo-specific network lookup logic out of `_shared/database`. It selects public or private subnets by `tag:Name` based on `publicly_accessible` and passes the resulting subnet ids into the shared Aurora module.
The database credentials outputs point at the Aurora-managed master secret rather than a repo-created fixed-name secret. The shared cluster module pins that secret to the AWS-managed Secrets Manager key `alias/aws/secretsmanager`.
