# Discovery And Matrices

Use this when changing directory discovery, runtime matrices, service/container naming, or Terragrunt graph waves.

## Directory Discovery

`shared_directories_get.yml` derives directory-based matrices used by wrapper workflows and PR action-test discovery.

`service_dirs` and `container_dirs` are intentionally different:

- `service_dirs` contains deployable ECS service image directories only.
- `container_dirs` also includes shared ECS sidecar image targets such as `debug` and `otel_collector`.
- ECS artifact builds that feed `shared_build.yml` should use `container_dirs` for `ecs_matrix`, because ECS task deploys need shared sidecar images as well as service images.
- Workflows that only need app service names or task/service stack derivation should use `service_dirs`.

Top-level runtime discovery rules:

- top-level Lambda directories under `lambdas/` are deployable functions, excluding generated build output
- top-level deployable ECS service directories under `containers/` are exposed through `service_dirs`
- the broader `container_dirs` matrix includes deployable service directories plus shared sidecar image targets

## Module Discovery

`shared_get_modules.yml` is the reusable module-discovery workflow for infra waves.

- Renders the Terragrunt graph for the target environment.
- Converts that graph into compact JSON.
- Derives dependency-safe waves.
- Exposes `waves_json`, `wave_0_modules`, `wave_1_modules`, `wave_2_modules`, and `wave_3_modules` as reusable-workflow outputs.

Filtering inputs:

- `ignore_task_modules: true` excludes `task_*` modules from emitted rollout waves for the current bootstrap-oriented infra path.
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

- If Lambda directories are auto-detected, confirm matching live Terragrunt stacks still exist.
- If ECS directories are auto-detected, confirm matching `task_*` and `service_*` live Terragrunt stacks still exist.
- For `*_code` wrappers, confirm dispatch inputs cover every runtime being deployed.
- If ECS deploys are included, confirm `ecs_version` is exposed or intentionally derived.
