# Discovery And Matrices

Use this when changing directory discovery, runtime matrices, service/container naming, or Terragrunt graph waves.

## Directory Discovery

`shared_directories_get.yml` derives ECS and repo-local action matrices used by wrapper workflows and PR action-test discovery.

Lambda discovery is manifest-based:

- `lambdas/deploy.yml` is the source of truth for Lambda build and deploy records.
- `shared_build.yml` derives unique Lambda source records from the manifest when it runs.
- `shared_deploy.yml` derives every Lambda deploy record from the manifest when it runs.
- wrapper workflows do not pass Lambda matrices; changing the Lambda deployment set is a `lambdas/deploy.yml` change.
- `stack` values are repo-relative Terragrunt stack path templates such as `infra/live/{environment}/aws/lambda_api`.
- `source_dir` values are repo-relative source paths; the artifact filename is computed from `basename(source_dir)`.

`service_dirs` and `container_dirs` are intentionally different:

- `service_dirs` contains deployable ECS service image directories only.
- `container_dirs` also includes shared ECS sidecar image targets such as `debug` and `otel_collector`.
- ECS artifact builds that feed `shared_build.yml` should use `container_dirs` for `ecs_matrix`, because ECS task deploys need shared sidecar images as well as service images.
- Workflows that only need app service names or task/service stack derivation should use `service_dirs`.

Top-level runtime discovery rules:

- Lambda deployability is declared in `lambdas/deploy.yml`; top-level Lambda directories are not deploy targets unless the manifest references them
- top-level deployable ECS service directories under `containers/` are exposed through `service_dirs`
- the broader `container_dirs` matrix includes deployable service directories plus shared sidecar image targets

## Module Discovery

`shared_get_modules.yml` is the reusable module-discovery workflow for infra waves.

- Renders the Terragrunt graph for the target environment.
- Converts that graph into compact JSON.
- Derives dependency-safe waves.
- Exposes `waves_json` and `wave_0_modules` through `wave_3_modules` as reusable-workflow outputs.
- The static workflow wave outputs/jobs must be kept aligned with the dependency depth required by the live environment subset being deployed.

Filtering inputs:

- `ignore_task_modules: true` excludes `task_*` modules from emitted waves. Infra plan/apply callers use this because task-definition stacks belong to code deploy, not shared infra rollout.
- `ignore_shared_artifact_modules: true` omits shared artifact stacks such as `code_bucket` and `ecr`.
- `ignore_oidc_module: true` excludes `oidc` entirely.
- `show_wave_summary: false` suppresses the raw wave matrix step summary when a caller provides a more focused summary.

## Graph To Waves Helper

`just --justfile justfile.ci tg-graph-json-to-waves` expects compact graph JSON in `TG_GRAPH_JSON`.

It returns a sequential JSON array of wave objects:

```json
[{ "wave": 0, "modules": [] }]
```

Each wave contains only modules whose direct dependencies were satisfied by earlier waves.

## Runtime Coverage Checks

- If Lambda manifest entries change, confirm each `stack` path exists for every deployed environment and each `source_dir` still builds.
- If ECS directories are auto-detected, confirm matching `task_*` and `service_*` live Terragrunt stacks still exist.
- For `*_code` wrappers, confirm dispatch inputs cover every runtime being deployed.
- If ECS deploys are included, confirm `ecs_version` is exposed or intentionally derived.
