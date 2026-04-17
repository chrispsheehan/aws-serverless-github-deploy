# `lambda_api`

Lambda-backed public HTTP API module.

## Owns

- Lambda API function via `_shared/lambda`
- Lambda proxy integration into the shared HTTP API
- root and proxy routes on the shared API
- API 5xx CloudWatch alarm
- least-scope SNS publish access for the shared worker-events topic

## Dependencies

- shared API Gateway HTTP API, VPC link, and JWT authorizer from `network`
- shared worker SNS topic from `worker_messaging`

## Key outputs

- `invoke_url`
- `api_id`
- `vpc_link_id`
- Lambda function and alias names

This module is Lambda-specific. The shared API surface and shared JWT authorizer now live in `network`.
When accessed through the frontend CloudFront distribution, the public Lambda path is `/api/*` because CloudFront strips the leading `/api` prefix before forwarding to API Gateway.
The packaged runtime can publish JSON payloads to the shared worker SNS topic via `POST /messages`, which fans the message out to both the Lambda and ECS worker queues.
