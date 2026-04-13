# `api`

Lambda-backed public HTTP API module.

## Owns

- Lambda API function via `_shared/lambda`
- Lambda proxy integration into the shared HTTP API
- root and proxy routes on the shared API
- API 5xx CloudWatch alarm

## Dependencies

- shared API Gateway HTTP API and VPC link from `network`
- shared security state

## Key outputs

- `invoke_url`
- `api_id`
- `vpc_link_id`
- Lambda function and alias names

This module is Lambda-specific. The shared API surface now lives in `network`.
When accessed through the frontend CloudFront distribution, the public Lambda path is `/api/*` because CloudFront strips the leading `/api` prefix before forwarding to API Gateway.
