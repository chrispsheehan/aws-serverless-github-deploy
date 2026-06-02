# Artifacts And Saved Plans

Use this when changing saved plans, apply-from-plan behavior, plan metadata, artifact naming, or cross-run recovery.

## Plan Wrapper

`shared_infra_plan.yml` is the saved-plan wrapper.

- Takes resolved workflow inputs directly.
- Starts `shared_get_modules.yml` to derive current wave outputs.
- Writes waves plus direct workflow inputs into one run-level `plan-metadata.json`.
- Uploads that file as the GitHub Actions artifact named `infra-plan-metadata`.
- Runs direct Terragrunt `plan` jobs in dependency-safe wave order.
- After planning, prints `github.run_id` in logs and step summary as `plan_artifact_run_id`.
- Exposes `plan_artifact_run_id` as a reusable-workflow output.
- Adds a plan summary showing planned waves and modules whose saved `terragrunt.plan.meta.json` reports `has_changes: true`.
- Writes a step-summary warning that saved plan artifacts are time-limited and must be applied before artifact expiry.

## Apply Wrappers

`shared_infra_apply_no_plan.yml` is the direct-input apply wrapper.

- Takes resolved workflow inputs directly.
- Derives current graph waves and runs direct Terragrunt `apply` jobs.
- Uses the module-discovery wave summary so the run page shows environment, infra version, selected module count, and modules grouped by wave before apply jobs run.

`shared_infra_apply_from_plan.yml` is the apply-from-plan wrapper.

- Takes `plan_artifact_run_id`.
- Downloads `infra-plan-metadata` from the earlier workflow run.
- Reads frozen graph inputs and saved wave arrays.
- Reruns the same `wave_0` through `wave_3` module order.
- Each per-module job downloads its matching `terragrunt-plan-<environment>-<module>` artifact into the live stack directory.
- Each per-module job invokes the repo-local Terragrunt action with `tg_action: apply_plan`.
- The wrapper filters saved rollout waves through the read-only `infra-plan-filter-waves-by-changes` helper in `justfile.ci`, so apply excludes modules whose saved `terragrunt.plan.meta.json` reports `has_changes: false`.
- The metadata job writes an apply-from-plan summary with recovered infra version, plan artifact run id, and the filtered modules grouped by wave.

## Saved Plan Files

The repo-local `./.github/actions/terragrunt` action supports `tg_action: plan`.

- Produces the binary plan in the live stack directory.
- Writes `terragrunt.plan.meta.json` for every saved plan.
- Metadata includes `has_changes` and `contains_mocked_outputs`.
- Writes `terragrunt.plan.txt` alongside the binary plan when the plan has changes.

`apply_plan` expects the workflow job to download the matching per-stack artifact into the live stack directory before invoking Terragrunt.

- `terragrunt.plan.meta.json` must be present.
- `apply_plan` fails immediately if metadata is missing.
- `apply_plan` fails immediately if `contains_mocked_outputs: true`.

Saved infra-plan storage is intentionally split into two levels:

- run-level artifact: `infra-plan-metadata`, containing `plan-metadata.json`
- per-stack artifact: `terragrunt-plan-<environment>-<module>`

The saved plan set is time-limited. `infra-plan-metadata` is uploaded with `retention-days: 14`, so apply-from-plan must happen before that artifact expires. Per-stack plan artifacts should keep their retention aligned with the metadata artifact; if they do not set `retention-days` explicitly, they inherit the repository or GitHub artifact default.

`./.github/actions/terragrunt` derives its plan artifact name from `tg_directory`, so callers do not need to pass artifact naming inputs.

## Cross-Run Recovery

If `apply_plan` is used across separate workflow runs, pass the earlier workflow `run_id` through `plan_artifact_run_id`.

- Shared wrappers recover run-level metadata and per-stack plan files from GitHub artifacts in that earlier run.
- Recovery only works while the metadata and per-stack plan artifacts are still retained.
- If cross-run apply should not ask the operator to re-enter versions or recompute artifact resolution, store both input versions and resolved reusable-workflow outputs in metadata during plan.
- Recover those values in the apply wrapper from the earlier `run_id`.

Keep `shared_infra.yml` as the pure graph executor. Prefer handling metadata creation and recovery in dedicated plan/apply wrappers.

## Mock Outputs

When a live Terragrunt `dependency` block uses `mock_outputs` for planability or destroy safety, default it to:

```hcl
mock_outputs_merge_strategy_with_state = "shallow"
```

That prevents partial real upstream state from suppressing missing mock keys.
