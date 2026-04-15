# `lambda_worker`

Worker Lambda wrapper module.

## Owns

- worker Lambda via `_shared/lambda`
- Lambda worker event-source mapping onto the shared worker messaging queue
- DLQ alarming for the Lambda worker queue

## Key outputs

- Lambda function and alias names
- queue name and queue URLs
- SQS read policy ARN
- log group

This is the concrete worker implementation on top of the shared Lambda primitives. It reads the Lambda worker queue from the `worker_messaging` stack so the same SNS event can fan out to both the Lambda and ECS worker consumers.
