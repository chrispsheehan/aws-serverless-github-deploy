# `rds_reader_tagger`

Syncs Aurora reader instance tags from the parent cluster tags.

## What It Does

- listens for the Aurora reader scale-out instance-created event through EventBridge
- can also be invoked directly with an empty payload to scan existing readers in the cluster
- reads the cluster tags
- syncs the cluster's non-AWS tags onto reader instances

## Invocation Modes

- EventBridge mode: handle `RDS-EVENT-0005` and reconcile the new reader only
- Direct mode: invoke with `{}` or no `detail` payload and reconcile all readers in the expected cluster

The direct mode is safe to run repeatedly. It only adds missing or changed non-AWS tags and removes extra non-AWS tags that are not present on the cluster.

## Event Shape

- source: `aws.rds`
- detail-type: `RDS DB Instance Event`
- event id: `RDS-EVENT-0005`

## Operational Notes

- the Lambda skips events for DB instances that do not belong to the expected cluster for the current environment
- direct-invoke mode reconciles all current readers in the expected cluster, not just readers created after the stack was deployed
- AWS-managed tags are left alone
- documentation files in this directory are pruned from the packaged Lambda zip during build
