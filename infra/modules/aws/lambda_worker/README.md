# `lambda_worker`

Worker Lambda wrapper module.

## Owns

- worker Lambda via `_shared/lambda`
- worker queue integration via `_shared/sqs`

## Key outputs

- Lambda function and alias names
- queue URLs
- log group

This is the concrete worker implementation on top of the shared Lambda primitives.
