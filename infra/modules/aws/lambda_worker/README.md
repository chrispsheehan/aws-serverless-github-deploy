# `lambda_worker`

Worker Lambda wrapper module.

## Owns

- worker Lambda via `_shared/lambda`
- Lambda worker queue integration via `_shared/sqs`

## Key outputs

- Lambda function and alias names
- queue name and queue URLs
- SQS read policy ARN
- queue URLs
- log group

This is the concrete worker implementation on top of the shared Lambda primitives. Its queue is owned for Lambda worker processing and is no longer the queue used by the ECS worker service.
