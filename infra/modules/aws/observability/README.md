# `observability`

CloudWatch dashboard for repo runtime logs.

## Owns

- one CloudWatch dashboard for the environment
- Logs Insights widgets for Lambda logs, ECS application logs, and ECS OTEL sidecar logs

## Does Not Own

- CloudWatch log groups themselves
- alarming, tracing configuration, or runtime log retention

## Inputs That Change Behavior

- `project_name`
- `environment`
- `aws_region`

## Outputs Consumers Rely On

- `dashboard_name`
- `dashboard_url`

## Dependency Notes

- relies on the shared Lambda and ECS log-group naming conventions already used in this repo
- does not require direct remote-state reads from runtime stacks because the dashboard queries log-group prefixes

## Runtime Behavior

- provides one console place to inspect recent Lambda logs for the current environment
- provides one console place to inspect recent ECS app logs
- provides one console place to inspect recent ECS OTEL sidecar logs
