#!/usr/bin/env bash
set -euo pipefail

mode="${1:?mode is required}"
logical_tg_dir="${2:?terragrunt directory is required}"
plan_bucket="${3:?plan bucket is required}"
environment="${4:?environment is required}"
infra_plan_dir="${INFRA_PLAN_DIR:-terragrunt_plan}"

plan_path="${PWD}/terragrunt.tfplan"
plan_text_path="${PWD}/terragrunt.plan.txt"
plan_meta_path="${PWD}/terragrunt.plan.meta.json"
plan_json_path="${PWD}/terragrunt.plan.json"
plan_log_path="${PWD}/${TG_PLAN_LOG_FILENAME:-terragrunt.plan.log}"

if [[ "${TG_ENABLE_PLAN_ARTIFACTS:-false}" != "true" ]]; then
  echo "TG_ENABLE_PLAN_ARTIFACTS=false, skipping plan artifact ${mode}." >&2
  exit 0
fi

if [[ -z "${PLAN_ARTIFACT_RUN_ID:-}" ]]; then
  echo "PLAN_ARTIFACT_RUN_ID is required when TG_ENABLE_PLAN_ARTIFACTS=true." >&2
  exit 1
fi

sanitized_dir="$(echo "$logical_tg_dir" | tr '/.' '--')"
artifact_s3_prefix="s3://${plan_bucket}/${infra_plan_dir}/${environment}/${PLAN_ARTIFACT_RUN_ID}/terragrunt-plan-${sanitized_dir}"

case "$mode" in
  download)
    echo "Downloading plan artifacts from ${artifact_s3_prefix}" >&2
    aws s3 cp "${artifact_s3_prefix}/terragrunt.tfplan" "$plan_path"
    aws s3 cp "${artifact_s3_prefix}/terragrunt.plan.txt" "$plan_text_path"
    aws s3 cp "${artifact_s3_prefix}/terragrunt.plan.meta.json" "$plan_meta_path"
    echo "Downloaded plan artifacts for ${logical_tg_dir}" >&2

    if [[ "$(jq -r '.contains_mocked_outputs // false' "$plan_meta_path")" == "true" ]]; then
      echo "Saved plan for '$logical_tg_dir' contains mocked outputs. Regenerate it after upstream real outputs exist." >&2
      exit 1
    fi
    ;;
  upload)
    if [[ ! -f "$plan_path" ]]; then
      exit 0
    fi

    terraform show -no-color "$plan_path" > "$plan_text_path"
    terraform show -json "$plan_path" > "$plan_json_path"

    contains_mocked_outputs=false
    if [[ -f "$plan_log_path" ]] && grep -Fq "mock outputs provided and returning those in dependency output" "$plan_log_path"; then
      contains_mocked_outputs=true
    fi

    jq -n \
      --arg tg_directory "$logical_tg_dir" \
      --argjson has_changes "$(jq -r '([(.resource_changes // [])[]?.change.actions[]?] | any(. != "no-op")) or ((.output_changes // {}) | length > 0)' "$plan_json_path")" \
      --argjson contains_mocked_outputs "$contains_mocked_outputs" \
      '{tg_directory: $tg_directory, has_changes: $has_changes, contains_mocked_outputs: $contains_mocked_outputs}' \
      > "$plan_meta_path"

    echo "Uploading plan artifacts for ${logical_tg_dir} to ${artifact_s3_prefix}" >&2
    aws s3 cp "$plan_path" "${artifact_s3_prefix}/terragrunt.tfplan"
    aws s3 cp "$plan_text_path" "${artifact_s3_prefix}/terragrunt.plan.txt"
    aws s3 cp "$plan_meta_path" "${artifact_s3_prefix}/terragrunt.plan.meta.json"
    echo "Uploaded plan artifacts for ${logical_tg_dir}" >&2
    rm -f "$plan_json_path"
    ;;
  *)
    echo "Unknown mode '$mode'." >&2
    exit 2
    ;;
esac
