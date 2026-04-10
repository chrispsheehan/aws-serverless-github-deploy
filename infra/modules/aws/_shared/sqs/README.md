# `_shared/sqs`

Shared SQS queue module.

## Owns

- primary queue
- dead-letter queue
- redrive policy

## Key outputs

- queue URL
- dead-letter queue URL

Used by worker-style Lambda and ECS consumers.
