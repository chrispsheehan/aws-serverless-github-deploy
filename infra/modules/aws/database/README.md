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
- `recovery_class`
- `restore_drill`
- `manual_snapshot`
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
The database credentials outputs point at the Aurora-managed master secret rather than a repo-created fixed-name secret.
Aurora reader instances created later by scale-out can be paired with the separate `rds_reader_tagger` stack so new readers inherit the cluster's non-AWS tags.
Use `recovery_class` as the main resilience input and let the shared module derive retention, final-snapshot, deletion-protection, and reader-minimum defaults from that class.
Use `restore_drill` when you want the shared module to also provision the optional restore-drill Step Functions skeleton and any class-derived schedule.
Use `manual_snapshot` when you want the shared module to also provision a separate on-demand manual snapshot Step Functions trigger.
