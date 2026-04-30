# `_shared/database`

Shared Aurora PostgreSQL Serverless v2 module.

## Owns

- Aurora PostgreSQL cluster
- one writer instance and optional reader instances
- database subnet group
- SSM parameters for database name and endpoints
- the Aurora-managed Secrets Manager master credentials object for the database username and password
- a generated master username that always starts with a letter so Aurora accepts it reliably

## Does Not Own

- EventBridge automation around reader scale-out events
- downstream tag-sync behavior for reader instances created after initial apply

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
- `recovery_class`
- `restore_drill_cadence`
- `target_rpo_minutes`
- `target_rto_minutes`
- `restore_drill_enabled`
- `restore_drill_mode`
- `restore_drill_schedule_expression`
- `restore_drill_state_machine_arn`
- `restore_drill_state_machine_name`
- `manual_snapshot_enabled`
- `manual_snapshot_state_machine_arn`
- `manual_snapshot_state_machine_name`
- `manual_snapshot_identifier_prefix`

This module is intentionally Aurora PostgreSQL Serverless v2 specific. It does not currently support provisioned RDS instances or non-Postgres engines.
In this repo the concrete `database` wrapper resolves the VPC and public or private subnet ids, while the shared infra workflow injects `database_security_group_id` from the `security` stack via `TF_VAR_database_security_group_id`.
By default the module tracks the latest matching Aurora PostgreSQL 16.x engine version rather than pinning a specific patch release.
SSM parameter paths are rooted at `/<environment>/<project>/<database>/...` so they do not collide with AWS-reserved `/aws` prefixes.
The runtime contract for database credentials is the Aurora-managed master secret exposed from the cluster. Terraform reads the managed secret ARN directly from the cluster resource rather than doing a separate Secrets Manager lookup during the same apply, because AWS may not populate that managed-secret reference early enough for an immediate data read.
If you need new scale-out readers to inherit cluster tags, keep that automation in a separate stack such as `rds_reader_tagger` rather than pushing event-driven behavior into this shared database module.

## Recovery Classes

The shared module derives backup retention, deletion protection, final-snapshot behavior, minimum reader count, and recovery metadata from a single `recovery_class` input.

### `dev`

- 1 day of automated backup retention
- deletion protection disabled
- no final snapshot on destroy
- no required reader instances
- `restore_drill_cadence = "never"`

### `standard`

- 7 days of automated backup retention
- deletion protection enabled
- final snapshot required on destroy
- at least 1 reader instance when multiple subnet AZs are available
- `restore_drill_cadence = "monthly"`

### `critical`

- 35 days of automated backup retention
- deletion protection enabled
- final snapshot required on destroy
- at least 2 reader instances when enough subnet AZs are available
- `restore_drill_cadence = "weekly"`

The module publishes `RecoveryClass`, `RestoreDrillCadence`, `TargetRPOMinutes`, and `TargetRTOMinutes` as cluster tags so operators can see the intended recovery posture directly on the Aurora cluster.

## Restore Drill

The shared module can also provision an opt-in restore-drill skeleton inside the same database module. When enabled, it creates:

- a Step Functions state machine for manual restore-drill execution
- an optional EventBridge Scheduler schedule when the mode includes scheduled runs
- the IAM roles needed for the scheduler to start the state machine and for Step Functions to call RDS APIs

Example:

```hcl
recovery_class = "standard"

restore_drill = {
  enabled      = true
  mode         = "manual_and_scheduled"
  use_pitr     = true
  retain_hours = 4
}
```

The schedule expression is derived from `recovery_class`:

- `dev`: no automatic schedule
- `standard`: `rate(30 days)`
- `critical`: `rate(7 days)`

Rough cost guidance by recovery class:

- `dev`: lowest ongoing cost; 1-day automated backups, no final snapshot on destroy, no required reader instances, no scheduled drill by default
- `standard`: moderate cost increase; 7-day backups, final snapshot on destroy, at least 1 reader when multiple subnet AZs are available, monthly scheduled drill if enabled
- `critical`: highest ongoing cost; 35-day backups, final snapshot on destroy, at least 2 readers when enough subnet AZs are available, weekly scheduled drill if enabled

The largest drill-related cost is the temporary restored Aurora cluster and scratch writer instance. Step Functions and EventBridge Scheduler usually contribute negligible cost compared with Aurora compute and storage.

The current Step Functions skeleton:

1. restores a temporary Aurora cluster from PITR
2. waits for the scratch cluster to become available
3. creates one temporary writer instance
4. waits for the instance to become available
5. holds the restored environment for the configured retention window
6. deletes the temporary instance and cluster

This first version does not yet run application-level validation against the restored database. It proves restore orchestration and cleanup only. Add a dedicated validation Lambda or ECS task later once the restore path itself is stable.

## Manual Snapshot

The shared module can also provision an opt-in manual snapshot trigger. This is separate from the restore drill:

- `manual_snapshot` creates a named Aurora cluster snapshot on demand
- `restore_drill` restores a temporary cluster and validates the recovery path

Example:

```hcl
manual_snapshot = {
  enabled = true
}
```

When enabled, the module creates a second Step Functions state machine that:

1. builds a unique snapshot identifier
2. creates a manual Aurora cluster snapshot
3. waits until the snapshot reaches `available`

Use the `manual_snapshot_state_machine_arn` or `manual_snapshot_state_machine_name` output to start it manually from the Step Functions console or CLI.
The module also exposes `manual_snapshot_identifier_prefix` so destroy or cleanup paths can delete only the repo-owned manual snapshots without re-deriving the naming contract outside Terraform.
