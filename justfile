# List root recipes plus split CI/deploy recipe files.
_default:
    @just --list
    @printf '\nCI recipes (`just --justfile justfile.ci --list`):\n'
    @just --justfile justfile.ci --list
    @printf '\nTerragrunt recipes (`just --justfile justfile.tg --list`):\n'
    @just --justfile justfile.tg --list
    @printf '\nDeploy recipes (`just --justfile justfile.deploy --list`):\n'
    @just --justfile justfile.deploy --list


PROJECT_DIR := justfile_directory()
LAMBDA_DIR := "lambdas"
FRONTEND_DIR := "frontend"
INFRA_PLAN_DIR := "terragrunt_plan"


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
