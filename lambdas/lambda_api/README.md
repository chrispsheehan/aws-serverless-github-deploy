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
- the publish path also attaches trace headers as SNS message attributes so the ECS worker can continue the trace on the consumer side

The consumer-side trace continuation relies on the ECS tracing helper using the AWS X-Ray OpenTelemetry propagator, so the worker can understand the AWS-native trace header emitted from the Lambda/X-Ray side of the flow.

## Operational Notes

- the Lambda reads the shared worker topic ARN and name from environment variables wired by the `lambda_api` infra module
- logs are emitted through the shared JSON runtime logger
