_default:
    just --list


PROJECT_DIR := justfile_directory()
LAMBDA_DIR := "lambdas"
FRONTEND_DIR := "frontend"


lambda-invoke:
    #!/bin/bash
    set -euo pipefail

    if [[ -z "$LAMBDA_NAME" ]]; then
        echo "Error: LAMBDA_NAME environment variable is not set."
        exit 1
    fi

    OUTPUT_FILE=output.json
    PAYLOAD="{}"
    rm -f $OUTPUT_FILE
    RESPONSE=$(aws lambda invoke --cli-read-timeout 300 --function-name $LAMBDA_NAME --region $AWS_REGION --payload "$PAYLOAD" $OUTPUT_FILE)
    LAMBDA_RETURN_CODE=$(jq -r '.StatusCode' <<< "$RESPONSE")
    if [ "$LAMBDA_RETURN_CODE" -eq 200 ]; then
        echo "Lambda function invoked successfully."
    else
        echo "Lambda function failed with return code: $LAMBDA_RETURN_CODE"
    fi
    cat $OUTPUT_FILE
    LAMBDA_STATUS_CODE=$(jq -r '.statusCode // empty' "$OUTPUT_FILE")

    if [ "$LAMBDA_STATUS_CODE" = "200" ]; then
        echo "✅ Lambda function completed successfully."
        exit 0
    else
        echo "❌ Lambda function failed or returned non-200 status code: $LAMBDA_STATUS_CODE"
        exit 1
    fi


git-tidy:
    #!/usr/bin/env bash
    git fetch --prune
    for branch in $(git branch -vv | grep ': gone]' | awk '{print $1}'); do
        git branch -d $branch
    done


branch name:
    #!/usr/bin/env bash
    git fetch origin
    git checkout main
    git pull origin
    git checkout -b {{ name }}
    git push -u origin {{ name }}


format:
    #!/usr/bin/env bash
    terraform fmt -recursive
    terragrunt hclfmt


# Terragrunt operation on {{module}} containing terragrunt.hcl
tg env module op:
    #!/usr/bin/env bash
    cd {{justfile_directory()}}/infra/live/{{env}}/{{module}} ; terragrunt {{op}}


tg-all op:
    #!/usr/bin/env bash
    cd {{justfile_directory()}}/infra/live
    terragrunt run-all {{op}}


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


docker-build:
    #!/usr/bin/env bash
    set -euo pipefail

    if [[ -z "$CONTAINER_NAME" ]]; then
        echo "❌ CONTAINER_NAME environment variable is not set."
        exit 1
    fi

    TAG="${IMAGE_URI:-$CONTAINER_NAME}"

    docker build \
      --file "{{PROJECT_DIR}}/Dockerfile" \
      --build-arg "SERVICE=$CONTAINER_NAME" \
      --target "$CONTAINER_NAME" \
      -t "$TAG" \
      "{{PROJECT_DIR}}"


docker-mirror:
    #!/usr/bin/env bash
    set -euo pipefail

    if [[ -z "${SOURCE_IMAGE:-}" ]]; then
        echo "❌ SOURCE_IMAGE environment variable is not set."
        exit 1
    fi

    if [[ -z "${IMAGE_URI:-}" ]]; then
        echo "❌ IMAGE_URI environment variable is not set."
        exit 1
    fi

    docker pull "$SOURCE_IMAGE"
    docker tag "$SOURCE_IMAGE" "$IMAGE_URI"


docker-push:
    #!/usr/bin/env bash
    set -euo pipefail

    if [[ -z "${IMAGE_URI:-}" ]]; then
        echo "❌ IMAGE_URI environment variable is not set."
        exit 1
    fi

    registry="${IMAGE_URI%%/*}"
    aws_region="$(echo "$registry" | cut -d. -f4)"

    if [[ -z "$aws_region" ]]; then
        echo "❌ Could not determine AWS region from IMAGE_URI: $IMAGE_URI"
        exit 1
    fi

    aws ecr get-login-password --region "$aws_region" \
        | docker login --username AWS --password-stdin "$registry"

    docker push "$IMAGE_URI"


lambda-build:
    #!/usr/bin/env bash
    set -euo pipefail

    if [[ -z "$LAMBDA_NAME" ]]; then
        echo "❌ LAMBDA_NAME environment variable is not set."
        exit 1
    fi

    python3 -m venv venv
    source venv/bin/activate

    LAMBDA_BUILD_DIR="{{PROJECT_DIR}}/{{LAMBDA_DIR}}/build"

    echo "🔄 Cleaning previous builds..."
    rm -rf $LAMBDA_BUILD_DIR

    echo "📦 Building $LAMBDA_NAME Lambda..."
    pip install --target "$LAMBDA_BUILD_DIR/$LAMBDA_NAME" -r "{{PROJECT_DIR}}/{{LAMBDA_DIR}}/$LAMBDA_NAME/requirements.txt"
    cp "{{PROJECT_DIR}}/{{LAMBDA_DIR}}/$LAMBDA_NAME"/*.py "$LAMBDA_BUILD_DIR/$LAMBDA_NAME/"
    cp "{{PROJECT_DIR}}/lambda_shared.py" "$LAMBDA_BUILD_DIR/$LAMBDA_NAME/"
    cp "{{PROJECT_DIR}}/db_shared.py" "$LAMBDA_BUILD_DIR/$LAMBDA_NAME/"
    cp "{{PROJECT_DIR}}/runtime_logging.py" "$LAMBDA_BUILD_DIR/$LAMBDA_NAME/"
    if [[ -d "{{PROJECT_DIR}}/{{LAMBDA_DIR}}/$LAMBDA_NAME/database_models" ]]; then
        cp -R "{{PROJECT_DIR}}/{{LAMBDA_DIR}}/$LAMBDA_NAME/database_models" "$LAMBDA_BUILD_DIR/$LAMBDA_NAME/"
    fi
    find "$LAMBDA_BUILD_DIR/$LAMBDA_NAME" -type f -name '*.md' -delete
    (
        cd "$LAMBDA_BUILD_DIR/$LAMBDA_NAME"
        zip -r "../../$LAMBDA_NAME.zip" . > /dev/null
    )
    echo "✅ Done: lambdas/$LAMBDA_NAME.zip"


lambda-upload:
    #!/usr/bin/env bash
    set -euo pipefail

    if [[ -z "$LAMBDA_NAME" ]]; then
        echo "❌ LAMBDA_NAME environment variable is not set."
        exit 1
    fi

    if [[ -z "$BUCKET_NAME" ]]; then
        echo "❌ BUCKET_NAME environment variable is not set."
        exit 1
    fi

    if [[ -z "$VERSION" ]]; then
        echo "❌ VERSION environment variable is not set."
        exit 1
    fi

    LAMBDA_ZIP="{{PROJECT_DIR}}/{{LAMBDA_DIR}}/$LAMBDA_NAME.zip"
    echo "📤 Uploading $LAMBDA_ZIP to s3://$BUCKET_NAME/lambdas/$VERSION/$LAMBDA_NAME.zip"

    aws s3 cp "$LAMBDA_ZIP" "s3://$BUCKET_NAME/lambdas/$VERSION/$LAMBDA_NAME.zip" \
        --storage-class STANDARD


frontend-build:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "🔄 Cleaning previous builds..."
    rm -rf {{PROJECT_DIR}}/{{FRONTEND_DIR}}/dist
    echo "📦 Building frontend..."
    npm install --prefix {{FRONTEND_DIR}}
    npm run build --prefix {{FRONTEND_DIR}}


frontend-upload:
    #!/usr/bin/env bash
    set -euo pipefail

    if [[ -z "$BUCKET_NAME" ]]; then
        echo "❌ BUCKET_NAME environment variable is not set."
        exit 1
    fi

    if [[ -z "$VERSION" ]]; then
        echo "❌ VERSION environment variable is not set."
        exit 1
    fi

    cd {{PROJECT_DIR}}/dist
    zip -r {{PROJECT_DIR}}/frontend.zip .
    aws s3 cp {{PROJECT_DIR}}/frontend.zip "s3://$BUCKET_NAME/frontend/$VERSION/frontend.zip"
    echo "✅ Frontend uploaded to s3://$BUCKET_NAME/frontend/$VERSION/frontend.zip"


frontend-deploy:
    #!/usr/bin/env bash
    set -euo pipefail

    if [[ -z "$BUCKET_NAME" ]]; then
        echo "❌ BUCKET_NAME environment variable is not set."
        exit 1
    fi

    if [[ -z "$VERSION" ]]; then
        echo "❌ VERSION environment variable is not set."
        exit 1
    fi

    if [[ -z "$WEBSITE_BUCKET" ]]; then
        echo "❌ WEBSITE_BUCKET environment variable is not set."
        exit 1
    fi

    TMPDIR=$(mktemp -d)
    aws s3 cp "s3://$BUCKET_NAME/frontend/$VERSION/frontend.zip" "$TMPDIR/frontend.zip"
    unzip -q "$TMPDIR/frontend.zip" -d "$TMPDIR/dist"
    aws s3 sync "$TMPDIR/dist/" "s3://$WEBSITE_BUCKET/" --delete --exclude "auth-config.json"
    echo "✅ Frontend deployed to s3://$WEBSITE_BUCKET"


frontend-invalidate:
    #!/usr/bin/env bash
    set -euo pipefail
    if [[ -z "$DISTRIBUTION_ID" ]]; then
        echo "Error: VERSION environment variable is not set."
        exit 1
    fi

    MAX_ATTEMPTS=30
    SLEEP_INTERVAL=10

    echo "🔄 Creating CloudFront invalidation..."
    INVALIDATION_ID=$(aws cloudfront create-invalidation \
        --distribution-id "$DISTRIBUTION_ID" \
        --paths "/*" \
        --query 'Invalidation.Id' \
        --output text)

    for ((i=1; i<=MAX_ATTEMPTS; i++)); do
    STATUS=$(aws cloudfront get-invalidation \
        --distribution-id "$DISTRIBUTION_ID" \
        --id "$INVALIDATION_ID" \
        --query 'Invalidation.Status' \
        --output text)

    echo "Attempt $i: Invalidation status is $STATUS"

    if [[ "$STATUS" == "Completed" ]]; then
        echo "✅ Invalidation $INVALIDATION_ID completed successfully."
        exit 0
    fi

    sleep "$SLEEP_INTERVAL"
    done

    echo "❌ Invalidation $INVALIDATION_ID did not complete within expected time."
    exit 1


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
