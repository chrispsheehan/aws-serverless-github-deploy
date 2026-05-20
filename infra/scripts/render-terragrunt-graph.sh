#!/usr/bin/env bash
set -euo pipefail

environment="${1:?environment is required}"
provider="${2:?provider is required}"

infra_plan_dir="${INFRA_PLAN_DIR:-terragrunt_plan}"
plan_run_id="${TG_GRAPH_METADATA_PLAN_RUN_ID:-}"
aws_region="${AWS_REGION:-}"
bucket_name="${BUCKET_NAME:-}"

graph_output="$(cat)"

nodes_json="$(
  printf '%s\n' "$graph_output" \
    | awk '
        /->/ { next }
        /digraph[[:space:]]*\{/ { next }
        /\}/ { next }
        /"/ {
          match($0, /"[^"]+"/)
          if (RSTART > 0) {
            print substr($0, RSTART + 1, RLENGTH - 2)
          }
        }
      ' \
    | sort -u \
    | jq -Rsc 'split("\n") | map(select(length > 0))'
)"

edges_json="$(
  printf '%s\n' "$graph_output" \
    | awk '
        /->/ {
          match($0, /"[^"]+"/)
          from = substr($0, RSTART + 1, RLENGTH - 2)
          remainder = substr($0, RSTART + RLENGTH)
          match(remainder, /"[^"]+"/)
          to = substr(remainder, RSTART + 1, RLENGTH - 2)
          print from "\t" to
        }
      ' \
    | jq -Rsc '
        split("\n")
        | map(select(length > 0))
        | map(split("\t"))
        | map({from: .[0], to: .[1]})
      '
)"

graph_json="$(
  jq -n \
    --arg environment "$environment" \
    --arg provider "$provider" \
    --argjson nodes "$nodes_json" \
    --argjson edges "$edges_json" \
    '
      {
        environment: $environment,
        provider: $provider,
        nodes: $nodes,
        edges: $edges,
        dependencies: (
          reduce $nodes[] as $node
            ({};
             .[$node] = (
               $edges
               | map(select(.from == $node) | .to)
               | sort
             )
            )
        )
      }
    '
)"

if [[ -z "$plan_run_id" ]]; then
  printf '%s\n' "$graph_json"
  exit 0
fi

if [[ -z "$aws_region" ]]; then
  echo "AWS_REGION is required when TG_GRAPH_METADATA_PLAN_RUN_ID is set." >&2
  exit 1
fi

if [[ -z "$bucket_name" ]]; then
  echo "BUCKET_NAME is required when TG_GRAPH_METADATA_PLAN_RUN_ID is set." >&2
  exit 1
fi

metadata_dir="$(mktemp -d)"
trap 'rm -rf "$metadata_dir"' EXIT

run_prefix="s3://${bucket_name}/${infra_plan_dir}/${environment}/${plan_run_id}/"

aws s3 sync \
  "$run_prefix" \
  "$metadata_dir" \
  --exclude "*" \
  --include "*/terragrunt.plan.meta.json" \
  >/dev/null

metadata_files=()
while IFS= read -r -d '' file; do
  metadata_files+=("$file")
done < <(find "$metadata_dir" -type f -name 'terragrunt.plan.meta.json' -print0 | sort -z)

if [[ "${#metadata_files[@]}" -eq 0 ]]; then
  jq -n \
    --arg environment "$environment" \
    --arg provider "$provider" \
    --arg plan_run_id "$plan_run_id" \
    '{environment: $environment, provider: $provider, plan_run_id: $plan_run_id, items: {}}'
  exit 0
fi

jq -s \
  --arg environment "$environment" \
  --arg provider "$provider" \
  --arg plan_run_id "$plan_run_id" \
  --argjson graph "$graph_json" \
  '
    def basename_from_tg_directory:
      split("/") | last;

    reduce (
      .[]
      | select(.tg_directory != null)
    ) as $meta (
      {
        environment: $environment,
        provider: $provider,
        plan_run_id: $plan_run_id,
        items: {}
      };
      ($meta.tg_directory | basename_from_tg_directory) as $stack
      | if ($graph.nodes | index($stack)) == null then
          .
        else
          .items[$stack] = (
            $meta
            + {
                dependencies: ($graph.dependencies[$stack] // [])
              }
          )
        end
    )
  ' \
  "${metadata_files[@]}"
