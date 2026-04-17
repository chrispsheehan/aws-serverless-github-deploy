# `rds_reader_tagger`

Tags newly created Aurora reader instances from the parent cluster tags.

## What It Does

- listens for the Aurora reader scale-out instance-created event through EventBridge
- describes the new DB instance to find its parent cluster
- reads the cluster tags
- syncs the cluster's non-AWS tags onto the new reader instance

## Event Shape

- source: `aws.rds`
- detail-type: `RDS DB Instance Event`
- event id: `RDS-EVENT-0005`

## Operational Notes

- the Lambda skips events for DB instances that do not belong to the expected cluster for the current environment
- AWS-managed tags are left alone
- documentation files in this directory are pruned from the packaged Lambda zip during build
