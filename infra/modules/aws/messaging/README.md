# `messaging`

Shared messaging stack.

## Owns

- one SNS topic for worker-event fanout
- one SQS queue and DLQ for the Lambda worker consumer
- one SQS queue and DLQ for the ECS worker consumer
- SNS subscriptions and queue policies so one published message fans out to both queues

## Key outputs

- `worker_topic_name`
- `worker_topic_arn`
- `worker_topic_publish_policy_arn`
- `lambda_worker_queue_name`
- `lambda_worker_queue_url`
- `lambda_worker_queue_read_policy_arn`
- `ecs_worker_queue_name`
- `ecs_worker_queue_url`
- `ecs_worker_queue_read_policy_arn`

Use this stack when both worker runtimes should receive the same event payload independently.

## Direct Publish

Publish directly to the shared worker SNS topic:

```sh
TOPIC_ARN=arn:aws:sns:eu-west-2:123456789012:aws-serverless-github-deploy-dev-worker-events \
MESSAGE='{"job_id":"demo-1","source":"local","payload":{"hello":"world"}}' \
just sns-publish
```

That fanout path delivers the same message to the Lambda worker and ECS worker queues.
