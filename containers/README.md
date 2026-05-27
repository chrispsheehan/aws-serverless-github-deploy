# `containers`

Container source directories for this boilerplate.

## Structure

- each deployable service lives in its own top-level directory such as `api/` or `worker/`
- `lib/` contains ECS-only helper code used by deployable services and is intentionally not treated as a deployable image target
- a deployable ECS runtime also needs the corresponding live Terragrunt stacks
- task stacks use `infra/live/<environment>/aws/task_<name>/terragrunt.hcl`
- service stacks use `infra/live/<environment>/aws/service_<name>/terragrunt.hcl` when applicable

## Common Shape

- `<service>/app.py`
- `<service>/requirements.txt`
- optional `<service>/README.md` for service-specific application logic and runtime notes
- optional ECS-only helpers under `containers/lib/`

## Build Behavior

- ECS directory discovery auto-detects deployable top-level directories under `containers/`
- ECS image discovery only includes deployable service directories
- container images copy only the files referenced by the Dockerfile for the selected service shape, including shared helpers from `lib/` and `containers/lib/`
- markdown files in `containers/` are documentation only and are not included in container image artifacts
- detection alone is not enough: the runtime still needs matching Terragrunt task and service stacks
- local Docker services should be added explicitly to `docker-compose.local.yml` and `Dockerfile.local`
- the local Dockerfile can mirror the production parameterized pattern by passing a `SERVICE` build arg for each target
- Compose owns service-specific local commands and env overrides

## Boilerplate Patterns

- HTTP services can be paired with `task_<name>` and `service_<name>` wrappers
- internal workers can use queue-driven processing and non-HTTP health checks
- shared tracing helpers live under `containers/lib/` and can be reused across ECS runtimes
- shared logging and database helpers live under `lib/`

## Logging

- ECS runtimes should use the shared JSON logger from `lib/runtime_logging.py`
- logs are written to stdout so the ECS log driver forwards them to CloudWatch
- prefer structured fields via logger `extra={...}` rather than ad-hoc string interpolation

## Tracing

- ECS runtimes use the shared tracing helper under `containers/lib/`
- async Lambda -> SNS -> SQS -> ECS trace continuation relies on the AWS X-Ray OpenTelemetry propagator
- that propagator lets ECS consumers understand AWS-native X-Ray trace headers, not just W3C `traceparent`

## Local Runtime

- local ECS services run from `Dockerfile.local` and `docker-compose.local.yml`
- `ecs_api` is exposed at `http://localhost:18081`
- `ecs_worker` polls the local `ecs-worker-queue`
- local SQS is provided by ElasticMQ
- `watchfiles` restarts local ECS services when Python files change

Worker publish and verification commands live in [worker/README.md](worker/README.md).

## Runtime Documentation

- add a `README.md` inside a concrete service directory when the container has non-trivial request handling, worker behavior, or integration logic
- use that README to explain what the service does, the interfaces it exposes or consumes, important dependencies, and any operational or failure-mode notes

## Local Verification

The local ECS worker records these fields when it persists messages to PostgreSQL:

- `message_type`
- `correlation_id`
- `source_queue`
- `processed_at`

Use [worker/README.md](worker/README.md) for the publish and query commands.

## Related Docs

- ECS service rules: [infra/modules/aws/_shared/service/README.md](../infra/modules/aws/_shared/service/README.md)
- shared infra context: [infra/README.md](../infra/README.md)
