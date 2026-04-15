# `worker_messaging`

Shared worker messaging stack.

## Owns

- one SNS topic for worker-event fanout
- one SQS queue and DLQ for the Lambda worker consumer
- one SQS queue and DLQ for the ECS worker consumer
- SNS subscriptions and queue policies so one published message fans out to both queues

## Key outputs

- `sns_topic_arn`
- `sns_topic_publish_policy_arn`
- `lambda_worker_queue_name`
- `lambda_worker_queue_url`
- `lambda_worker_queue_read_policy_arn`
- `ecs_worker_queue_name`
- `ecs_worker_queue_url`
- `ecs_worker_queue_read_policy_arn`

Use this stack when both worker runtimes should receive the same event payload independently.
