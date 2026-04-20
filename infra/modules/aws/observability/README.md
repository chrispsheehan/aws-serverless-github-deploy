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

- relies on the current shared runtime surface in this repo and the concrete log-group names those runtimes emit to
- does not require direct remote-state reads from runtime stacks because the dashboard widgets query the known Lambda, ECS app, and ECS OTEL log groups directly with `SOURCE '<log-group-name>'` entries
- tracks the primary request/worker runtimes by default; optional helper Lambdas such as `migrations` and `rds_reader_tagger` are not included unless the dashboard contract is extended explicitly

## Runtime Behavior

- provides one console place to inspect recent primary Lambda logs for the current environment
- filters out Lambda platform `START`, `END`, and `REPORT` lines so the default view focuses on structured app events
- provides one console place to inspect recent ECS app logs
- prefers structured ECS app events in the default view rather than raw metadata-heavy log lines
- exposes one normalized `log_message` column in the default Lambda and ECS app views that prefers the parsed application `message` field and falls back to CloudWatch's raw `@message`
- provides one console place to inspect recent ECS OTEL sidecar logs
- keeps the OTEL widget focused on timestamp plus a normalized `log_message` column instead of showing raw CloudWatch source columns by default
