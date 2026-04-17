# `containers`

Container source directories for this boilerplate.

## Structure

- each deployable service lives in its own top-level directory such as `api/` or `worker/`
- `shared/` contains helper code used by deployable services and is intentionally not treated as a deployable image target
- a deployable ECS runtime also needs the corresponding live Terragrunt stacks such as `infra/live/<environment>/aws/task_<name>/terragrunt.hcl` and, when applicable, `infra/live/<environment>/aws/service_<name>/terragrunt.hcl`

## Common Shape

- `<service>/app.py`
- `<service>/requirements.txt`
- optional `<service>/README.md` for service-specific application logic and runtime notes
- optional shared helpers under `containers/shared/`

## Build Behavior

- ECS directory discovery auto-detects deployable top-level directories under `containers/`
- ECS image discovery only includes deployable service directories
- container images copy only the files referenced by the Dockerfile for the selected service shape
- markdown files in `containers/` are documentation only and are not included in container image artifacts
- detection alone is not enough: the runtime still needs the matching Terragrunt task and service stacks to participate in infra apply and code rollout correctly

## Boilerplate Patterns

- HTTP services can be paired with `task_<name>` and `service_<name>` wrappers
- internal workers can use queue-driven processing and non-HTTP health checks
- shared tracing helpers live under `containers/shared/` and can be reused across ECS runtimes

## Runtime Documentation

- add a `README.md` inside a concrete service directory when the container has non-trivial request handling, worker behavior, or integration logic
- use that README to explain what the service does, the interfaces it exposes or consumes, important dependencies, and any operational or failure-mode notes

## Related Docs

- ECS service rules: [infra/modules/aws/_shared/service/README.md](../infra/modules/aws/_shared/service/README.md)
- shared infra context: [infra/README.md](../infra/README.md)
