# `rds_reader_tagger`

EventBridge-triggered and directly invokable Lambda that syncs cluster tags onto Aurora reader instances.

## Owns

- the reader-tagging Lambda via `_shared/lambda`
- an EventBridge rule for Aurora reader instance creation events
- the least-scope IAM policy needed to read RDS metadata and sync tags
- the EventBridge-to-Lambda wiring against the Lambda live alias so the trigger follows normal Lambda code rollout

## Does Not Own

- the Aurora cluster itself
- reader autoscaling policy decisions
- shared Lambda deployment behavior from `_shared/lambda`

## Inputs That Change Behavior

- `code_bucket`
- `state_bucket`
- `otel_sample_rate`

## Outputs Consumers Rely On

- `lambda_function_name`
- `lambda_alias_name`
- `cloudwatch_log_group`
- `event_rule_name`

## Dependency Notes

- reads the shared `database` remote state to get the expected Aurora cluster identifier
- relies on the shared Lambda build and deploy flow for shipping the tagging code
- when `rds_reader_tagger` is present in the Lambda deploy matrix, the reusable `deploy.yml` workflow invokes it once after Lambda rollout so existing readers are reconciled too
- uses a shortened AWS resource-name prefix (`rds-tag-sync`) so the Lambda, IAM, CodeDeploy, and EventBridge resources stay within AWS name limits while the stack directory remains `rds_reader_tagger`

## Runtime Behavior

- listens for `RDS-EVENT-0005` through EventBridge
- when directly invoked with an empty payload, scans all current readers in the expected cluster
- derives the parent Aurora cluster from the new DB instance for event-driven reconciles
- copies the cluster's non-AWS tags onto reader instances
- skips events that do not belong to the expected cluster for the current environment
- is idempotent, so repeated direct invokes are safe for CI-triggered reconciliation
