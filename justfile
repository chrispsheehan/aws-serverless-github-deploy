# List root recipes plus split CI/deploy recipe files.
_default:
    @just --list
    @printf '\nCI recipes (`just --justfile justfile.ci --list`):\n'
    @just --justfile justfile.ci --list
    @printf '\nDeploy recipes (`just --justfile justfile.deploy --list`):\n'
    @just --justfile justfile.deploy --list
    @printf '\nDestroy recipes (`just --justfile justfile.destroy --list`):\n'
    @just --justfile justfile.destroy --list


# Start the local Postgres + migrations compose stack.
start:
    #!/usr/bin/env bash
    set -euo pipefail

    docker compose -f {{justfile_directory()}}/docker-compose.local.yml up --build -d
    npm --prefix {{justfile_directory()}}/frontend run dev -- --host 0.0.0.0 &

    open http://localhost:19300
    open http://localhost:5173
    docker compose -f {{justfile_directory()}}/docker-compose.local.yml logs -f


# Tear down the local compose stack and remove its volumes for a clean restart.
stop:
    docker compose -f {{justfile_directory()}}/docker-compose.local.yml down -v --remove-orphans


# Open a shell in the local debug container.
debug:
    @docker compose -f {{justfile_directory()}}/docker-compose.local.yml exec debug sh


# Run the local frontend dev server with CloudFront-like API path proxying.
frontend:
    @npm --prefix {{justfile_directory()}}/frontend run dev -- --host 0.0.0.0


# List rows from the local worker_messages table.
messages:
    @docker compose -f {{justfile_directory()}}/docker-compose.local.yml exec debug \
      psql -v ON_ERROR_STOP=1 \
      -c "select sqs_message_id, job_id, message_type, correlation_id, source_queue, processed_at, left(message_body, 120) as message_body_preview from worker_messages order by processed_at desc nulls last, sqs_message_id desc;"


# Publish a message directly to a local ElasticMQ queue by full queue name.
local-sqs-send queue_name='lambda-worker-queue':
    #!/usr/bin/env bash
    set -euo pipefail

    timestamp="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
    message_body="{\"job_id\":\"local-${timestamp}\",\"source\":\"local\",\"payload\":{\"timestamp\":\"${timestamp}\"}}"

    AWS_ACCESS_KEY_ID=elasticmq \
    AWS_SECRET_ACCESS_KEY=elasticmq \
    AWS_REGION="${AWS_REGION:-eu-west-2}" \
    aws sqs send-message \
      --endpoint-url http://localhost:19324 \
      --queue-url "http://localhost:19324/000000000000/{{queue_name}}" \
      --message-body "$message_body"


# Publish one message to both local worker queues, simulating local SNS fanout.
local-worker-publish:
    @just local-sqs-send lambda-worker-queue
    @just local-sqs-send ecs-worker-queue


PROJECT_DIR := justfile_directory()
LAMBDA_DIR := "lambdas"
FRONTEND_DIR := "frontend"
CONTAINERS_DIR := "containers"
APPSPEC_DIR := "appspec"
INFRA_PLAN_DIR := "terragrunt_plan"
EXTRA_CONTAINER_DIRECTORIES := "[\"debug\",\"otel_collector\"]"
NON_SERVICE_CONTAINER_DIRECTORIES := "[\"lib\",\"_shared\"]"


# Return the Lambda artifact directory name.
code-bucket-get-lambda-artifact-dir:
    @echo {{LAMBDA_DIR}}


# Return the frontend artifact directory name.
code-bucket-get-frontend-artifact-dir:
    @echo {{FRONTEND_DIR}}


# Return the infra plan artifact directory name.
code-bucket-get-infra-plan-dir:
    @echo {{INFRA_PLAN_DIR}}


# Return the AppSpec artifact directory name.
code-bucket-get-appspec-artifact-dir:
    @echo {{APPSPEC_DIR}}


# Delete local git branches whose upstream refs have gone away.
git-tidy:
    #!/usr/bin/env bash
    git fetch --prune
    for branch in $(git branch -vv | grep ': gone]' | awk '{print $1}'); do
        git branch -d $branch
    done


terraform-tidy:
    #!/usr/bin/env bash
    set -euo pipefail

    TARGET_DIR="{{justfile_directory()}}/infra/live"
    echo "Cleaning in: $TARGET_DIR"

    # Remove .terragrunt-cache directories
    find "$TARGET_DIR" -type d -name ".terragrunt-cache" -prune -exec rm -rf {} +

    # Remove .terraform.lock.hcl files
    find "$TARGET_DIR" -type f -name ".terraform.lock.hcl" -exec rm -f {} +

    echo "Done."


# Create and push a new branch from the latest `main`.
branch name:
    #!/usr/bin/env bash
    git fetch origin
    git checkout main
    git pull origin
    git checkout -b {{ name }}
    git push -u origin {{ name }}


# Run Terraform and Terragrunt formatting locally.
format:
    #!/usr/bin/env bash
    terraform fmt -recursive
    terragrunt hclfmt


# Run a Terragrunt operation for one environment/module pair.
tg env module op:
    #!/usr/bin/env bash
    cd {{justfile_directory()}}/infra/live/{{env}}/{{module}} ; terragrunt {{op}}


# Run a Terragrunt operation across all live stacks.
tg-all op:
    #!/usr/bin/env bash
    cd {{justfile_directory()}}/infra/live
    terragrunt run-all {{op}}


# Print the raw Terragrunt run-all dependency graph.
tg-graph env provider='aws':
    #!/usr/bin/env bash
    set -euo pipefail
    cd {{justfile_directory()}}/infra/live/{{env}}/{{provider}}

    terragrunt run-all graph-dependencies \
      --terragrunt-non-interactive \
      --terragrunt-include-external-dependencies


# Process a saved raw Terragrunt graph file into compact dependency JSON.
# Set TG_GRAPH_METADATA_PLAN_RUN_ID and BUCKET_NAME to join saved-plan metadata.
tg-graph-process graph_path env provider='aws':
    #!/usr/bin/env bash
    set -euo pipefail
    cd {{justfile_directory()}}

    if [[ ! -f "{{graph_path}}" ]]; then
        echo "❌ Graph file '{{graph_path}}' does not exist."
        exit 1
    fi

    infra_plan_dir="${INFRA_PLAN_DIR:-terragrunt_plan}"
    plan_run_id="${TG_GRAPH_METADATA_PLAN_RUN_ID:-}"
    aws_region="${AWS_REGION:-}"
    bucket_name="${BUCKET_NAME:-}"
    tmp_nodes="$(mktemp)"
    tmp_edges="$(mktemp)"
    trap 'rm -f "$tmp_nodes" "$tmp_edges"' EXIT

    awk -F'"' '
      /->/ {
        if (NF >= 4) {
          print $2 "\t" $4
        }
        next
      }
      /^[[:space:]]*"/ && /;[[:space:]]*$/ {
        if (NF >= 2) {
          print $2
        }
      }
    ' "{{graph_path}}" \
      | while IFS= read -r line; do
          if [[ "$line" == *$'\t'* ]]; then
            printf '%s\n' "$line" >> "$tmp_edges"
          elif [[ -n "$line" ]]; then
            printf '%s\n' "$line" >> "$tmp_nodes"
          fi
        done

    nodes_json="$(
      {
        cat "$tmp_nodes"
        awk -F'\t' 'NF >= 2 { print $1; print $2 }' "$tmp_edges"
      } \
        | jq -R -s '
            split("\n")
            | map(select(length > 0))
            | map(split("/") | last)
            | unique
            | sort
          '
    )"

    edges_json="$(
      jq -R -s '
        split("\n")
        | map(select(length > 0))
        | map(split("\t"))
        | map(select(length == 2))
        | map({
            from: (.[0] | split("/") | last),
            to: (.[1] | split("/") | last)
          })
        | unique
        | sort_by(.from, .to)
      ' "$tmp_edges"
    )"

    graph_json="$(
      jq -cn \
        --arg environment "{{env}}" \
        --arg provider "{{provider}}" \
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
                   | unique
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

    if [[ -z "$bucket_name" ]]; then
        echo "❌ BUCKET_NAME is required when TG_GRAPH_METADATA_PLAN_RUN_ID is set."
        exit 1
    fi

    metadata_dir="$(mktemp -d)"
    trap 'rm -rf "$metadata_dir"' EXIT
    run_prefix="s3://${bucket_name}/${infra_plan_dir}/{{env}}/${plan_run_id}/"

    if [[ -n "$aws_region" ]]; then
        aws s3 sync \
          "$run_prefix" \
          "$metadata_dir" \
          --region "$aws_region" \
          --exclude "*" \
          --include "*/terragrunt.plan.meta.json" \
          >/dev/null
    else
        aws s3 sync \
          "$run_prefix" \
          "$metadata_dir" \
          --exclude "*" \
          --include "*/terragrunt.plan.meta.json" \
          >/dev/null
    fi

    metadata_files=()
    while IFS= read -r -d '' file; do
        metadata_files+=("$file")
    done < <(find "$metadata_dir" -type f -name 'terragrunt.plan.meta.json' -print0 | sort -z)

    if [[ "${#metadata_files[@]}" -eq 0 ]]; then
        jq -n \
          --arg environment "{{env}}" \
          --arg provider "{{provider}}" \
          --arg plan_run_id "$plan_run_id" \
          '{environment: $environment, provider: $provider, plan_run_id: $plan_run_id, items: {}}'
        exit 0
    fi

    jq -s \
      --arg environment "{{env}}" \
      --arg provider "{{provider}}" \
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


# Return only changed saved-plan graph items as an object array.
# Requires TG_GRAPH_METADATA_PLAN_RUN_ID and BUCKET_NAME so tg-graph-process
# emits saved-plan metadata under `.items`.
tg-graph-changed-items graph_path env provider='aws':
    #!/usr/bin/env bash
    set -euo pipefail
    cd {{justfile_directory()}}

    just tg-graph-process "{{graph_path}}" "{{env}}" "{{provider}}" \
      | jq -c '
          if (.items? | type) != "object" then
            error("tg-graph-changed-items requires tg-graph-process metadata mode.")
          else
            .items
            | to_entries
            | map(
                select(.value.has_changes == true)
                | (.value + {stack: .key})
              )
          end
        '


# Open an ECS Exec shell in the worker debug container.
worker-debug-shell env:
    #!/usr/bin/env bash
    set -euo pipefail

    if ! command -v session-manager-plugin >/dev/null 2>&1; then
        echo "❌ session-manager-plugin is not installed or not on PATH."
        exit 1
    fi

    aws_region="${AWS_REGION:-eu-west-2}"
    project_name="$(basename "{{PROJECT_DIR}}")"
    cluster_name="{{env}}-${project_name}-cluster"
    service_name="ecs-worker"
    container_name="${service_name}-debug"
    database_cluster_identifier="${project_name}-{{env}}-app-aurora"
    credentials_secret_id="$(
        aws rds describe-db-clusters \
          --region "$aws_region" \
          --db-cluster-identifier "$database_cluster_identifier" \
          --query 'DBClusters[0].MasterUserSecret.SecretArn' \
          --output text
    )"
    credentials_json="$(
        aws secretsmanager get-secret-value \
          --secret-id "$credentials_secret_id" \
          --region "$aws_region" \
          --query 'SecretString' \
          --output text
    )"
    db_user="$(printf '%s' "$credentials_json" | jq -r '.username')"
    db_password="$(printf '%s' "$credentials_json" | jq -r '.password')"

    escaped_db_user="${db_user//\'/\'\"\'\"\'}"
    escaped_db_password="${db_password//\'/\'\"\'\"\'}"

    task_arn="$(
        aws ecs list-tasks \
          --region "$aws_region" \
          --cluster "$cluster_name" \
          --service-name "$service_name" \
          --query 'taskArns[0]' \
          --output text
    )"

    if [[ -z "$task_arn" || "$task_arn" == "None" ]]; then
        echo "❌ No running task found for service ${service_name} in cluster ${cluster_name}."
        exit 1
    fi

    echo "🔌 Opening ECS Exec shell to ${container_name} in ${service_name}..."
    aws ecs execute-command \
      --region "$aws_region" \
      --cluster "$cluster_name" \
      --task "$task_arn" \
      --container "$container_name" \
      --interactive \
      --command "/bin/sh -lc 'export PGUSER='\''${escaped_db_user}'\''; export DB_USER='\''${escaped_db_user}'\''; export PGPASSWORD='\''${escaped_db_password}'\''; exec /bin/sh'"


# Create or update a readonly Cognito user in the target environment.
cognito-create-readonly-user env email password:
    #!/usr/bin/env bash
    set -euo pipefail

    aws_region="${AWS_REGION:-eu-west-2}"
    project_name="$(basename "{{PROJECT_DIR}}")"
    user_pool_id="$(
      aws cognito-idp list-user-pools \
        --region "$aws_region" \
        --max-results 60 \
        --query "UserPools[?Name=='${project_name}-{{env}}-users'].Id | [0]" \
        --output text
    )"

    if [[ -z "$user_pool_id" || "$user_pool_id" == "None" ]]; then
        echo "❌ Could not find Cognito user pool ${project_name}-{{env}}-users."
        exit 1
    fi

    user_exists="$(
      aws cognito-idp admin-get-user \
        --region "$aws_region" \
        --user-pool-id "$user_pool_id" \
        --username "{{email}}" \
        --query 'Username' \
        --output text 2>/dev/null || true
    )"

    if [[ -z "$user_exists" || "$user_exists" == "None" ]]; then
      aws cognito-idp admin-create-user \
        --region "$aws_region" \
        --user-pool-id "$user_pool_id" \
        --username "{{email}}" \
        --user-attributes Name=email,Value="{{email}}" Name=email_verified,Value=true \
        --message-action SUPPRESS >/dev/null
    fi

    aws cognito-idp admin-set-user-password \
      --region "$aws_region" \
      --user-pool-id "$user_pool_id" \
      --username "{{email}}" \
      --password "{{password}}" \
      --permanent >/dev/null

    aws cognito-idp admin-add-user-to-group \
      --region "$aws_region" \
      --user-pool-id "$user_pool_id" \
      --username "{{email}}" \
      --group-name readonly >/dev/null

    echo "✅ Ensured readonly Cognito user {{email}} exists in {{env}}."


# Publish a message directly to an SNS topic.
sns-publish:
    #!/usr/bin/env bash
    set -euo pipefail

    if [[ -z "${TOPIC_ARN:-}" ]]; then
        echo "❌ TOPIC_ARN environment variable is not set."
        exit 1
    fi

    if [[ -z "${MESSAGE:-}" ]]; then
        echo "❌ MESSAGE environment variable is not set."
        exit 1
    fi

    aws sns publish \
      --topic-arn "$TOPIC_ARN" \
      --message "$MESSAGE"
