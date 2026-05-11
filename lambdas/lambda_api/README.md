# `lambda_api`

Public Lambda-backed HTTP API.

## What It Does

- serves the basic public API responses for the boilerplate
- exposes health and forced-failure routes for rollout and alarm testing
- publishes JSON payloads to the shared worker SNS topic through `POST /messages`
- supports authenticated frontend browser-telemetry publishing through the same `POST /messages` path

## Routes

- `GET /`
  Basic success response
- `GET /health`
  Health response
- `GET /fail`
- `GET /error`
  Forced 500 response for alarm and rollback testing
- `POST /messages`
  Publishes the JSON request body to the shared worker SNS topic

## Publish Contract

- request body must be valid JSON
- the published SNS message body is the normalized JSON payload
- the API response includes the SNS `message_id` and topic name
- Lambda responses use API Gateway proxy-compatible JSON string bodies
- the publish path also attaches trace headers as SNS message attributes so the ECS worker can continue the trace on the consumer side

The consumer-side trace continuation relies on the ECS tracing helper using the AWS X-Ray OpenTelemetry propagator, so the worker can understand the AWS-native trace header emitted from the Lambda/X-Ray side of the flow.

## Operational Notes

- the Lambda reads the shared worker topic ARN and name from environment variables wired by the `lambda_api` infra module
- the SNS client endpoint can be overridden with `AWS_ENDPOINT_URL_SNS`, which the local compose service uses to point at a small local publish shim under `local/sns_harness.py`; that shim fans messages out directly to the local worker queues backed by the third-party ElasticMQ SQS-compatible mock
- logs are emitted through the shared JSON runtime logger
- unexpected SNS publish failures are logged as `lambda_api_publish_failed`
- publish attempts and normalized request metadata are logged as `lambda_api_publish_attempt` and `lambda_api_publish_request`
- the local compose `lambda_api` service uses the reusable local Lambda HTTP harness under `local/lambda_http_harness.py`, with the handler import path and port passed in from `Dockerfile.local`
- the local compose `lambda_api` service restarts on Python changes through `watchfiles` in `Dockerfile.local`
