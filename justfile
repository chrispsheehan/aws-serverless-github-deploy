_default:
    just --list


PROJECT_DIR := justfile_directory()
LAMBDA_DIR := "lambdas"
CONTAINERS_DIR := "containers"
FRONTEND_DIR := "frontend"
EXTRA_CONTAINER_DIRECTORIES := "[\"debug\",\"otel_collector\"]"
NON_SERVICE_CONTAINER_DIRECTORIES := "[\"shared\"]"


tf-lint-check:
    #!/bin/bash
    set -euo pipefail
    find infra/modules -type f -name '*.tf' -print0 \
      | xargs -0 -n1 dirname \
      | sort -u \
      | while read -r dir; do
          echo "🔍 Running tflint in $dir"
          tflint --chdir="$dir" --force
        done


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


lambda-check-version:
    #!/usr/bin/env bash
    set -euo pipefail

    FULL_BUCKET_NAME="$BUCKET_NAME/lambdas/$VERSION/"

    if ! aws s3api head-bucket --bucket "$BUCKET_NAME" >/dev/null 2>&1; then
        echo "❌ The bucket '$BUCKET_NAME' does not exist or is inaccessible."
        exit 1
    fi

    if ! aws s3 ls "$FULL_BUCKET_NAME" >/dev/null 2>&1; then
        echo "❌ The subpath '$VERSION' does not exist in bucket '$BUCKET_NAME'."
        exit 1
    fi

    FILES=$(aws s3 ls $FULL_BUCKET_NAME --recursive | wc -l | xargs)
    if [ "$FILES" -gt 0 ]; then
        echo "✅ $FILES file(s) found in $FULL_BUCKET_NAME"
    else
        echo "❌ No files found under $FULL_BUCKET_NAME"
        exit 1
    fi


get-version-files:
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

    FULL_BUCKET_PATH="s3://$BUCKET_NAME/lambdas/$VERSION/"

    aws s3api head-bucket --bucket "$BUCKET_NAME" >/dev/null
    aws s3 ls "$FULL_BUCKET_PATH" >/dev/null

    aws s3 ls "$FULL_BUCKET_PATH" --recursive \
      | awk '{print $4}' \
      | xargs -n1 basename \
      | sed 's/\.[^.]*$//' \
      | grep -v 'appspec' \
      | jq -R . \
      | jq -s -c .


get-version-file-keys:
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

    FULL_BUCKET_PATH="s3://$BUCKET_NAME/lambdas/$VERSION/"

    aws s3api head-bucket --bucket "$BUCKET_NAME" >/dev/null
    aws s3 ls "$FULL_BUCKET_PATH" >/dev/null

    aws s3 ls "$FULL_BUCKET_PATH" --recursive \
      | awk '{print $4}' \
      | grep '\.zip$' \
      | grep -v 'appspec' \
      | jq -R . \
      | jq -s -c .


get-ecr-version-images:
    #!/usr/bin/env bash
    set -euo pipefail

    if [[ -z "${REPOSITORY_URL:-}" ]]; then
        echo "❌ REPOSITORY_URL environment variable is not set."
        exit 1
    fi

    if [[ -z "${VERSION:-}" ]]; then
        echo "❌ VERSION environment variable is not set."
        exit 1
    fi

    repository_name="${REPOSITORY_URL#*/}"

    aws ecr describe-images \
      --repository-name "$repository_name" \
      --query 'imageDetails[].imageTags[]' \
      --output text \
      | tr '\t' '\n' \
      | grep -- "-$VERSION\$" \
      | sed "s/-$VERSION$//" \
      | jq -R . \
      | jq -s -c .


get-ecr-version-tasks:
    #!/usr/bin/env bash
    set -euo pipefail

    image_names="$(just --justfile "{{PROJECT_DIR}}/justfile" get-ecr-version-images)"

    jq -cn \
      --argjson images "$image_names" \
      '
      $images
      | map(select(. != "bootstrap" and . != "debug" and . != "otel_collector"))
      '


lambda-get-directories:
    #!/usr/bin/env bash
    set -euo pipefail
    find "{{LAMBDA_DIR}}" -mindepth 1 -maxdepth 1 -type d \
      | xargs -I{} basename "{}" \
      | tr '-' '_' \
      | jq -R . \
      | jq -s -c .

    
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


service-get-directories:
    #!/usr/bin/env bash
    set -euo pipefail

    find "{{CONTAINERS_DIR}}" -mindepth 1 -maxdepth 1 -type d \
      | xargs -I{} basename "{}" \
      | jq -R . \
      | jq -sc --argjson reserved '{{NON_SERVICE_CONTAINER_DIRECTORIES}}' 'map(select(. as $name | ($reserved | index($name) | not)))' \
      | jq -r '.[]' \
      | tr '-' '_' \
      | jq -R . \
      | jq -s -c .


task-get-directories:
    #!/usr/bin/env bash
    set -euo pipefail

    found_dirs="$(just --justfile "{{PROJECT_DIR}}/justfile" service-get-directories)"

    jq -cn \
      --argjson found "$found_dirs" \
      '$found | map("task_" + .)'


ecs-task-get-image-uris:
    #!/usr/bin/env bash
    set -euo pipefail

    if [[ -z "${ECS_IMAGE_URIS:-}" ]]; then
        echo "❌ ECS_IMAGE_URIS environment variable is not set."
        exit 1
    fi

    if [[ -z "${TASK_NAME:-}" ]]; then
        echo "❌ TASK_NAME environment variable is not set."
        exit 1
    fi

    service_name="${TASK_NAME#task_}"

    jq -cn \
      --argjson image_uris "$ECS_IMAGE_URIS" \
      --arg service_name "$service_name" \
      '
      {
        service_image_uri: ($image_uris | map(select(test(":" + $service_name + "-")))[0] // ""),
        debug_image_uri: ($image_uris | map(select(test(":debug-")))[0] // ""),
        otel_image_uri: ($image_uris | map(select(test(":otel_collector-")))[0] // "")
      }
      | if .service_image_uri == "" then error("Missing ECS image URI for " + $service_name) else . end
      | if .debug_image_uri == "" then error("Missing debug image URI") else . end
      | if .otel_image_uri == "" then error("Missing otel_collector image URI") else . end
      '


ecs-service-get-directories:
    #!/usr/bin/env bash
    set -euo pipefail

    found_dirs="$(just --justfile "{{PROJECT_DIR}}/justfile" service-get-directories)"

    jq -cn \
      --argjson found "$found_dirs" \
      '$found | map("service_" + .)'


container-get-directories:
    #!/usr/bin/env bash
    set -euo pipefail

    found_dirs="$(just --justfile "{{PROJECT_DIR}}/justfile" service-get-directories)"

    jq -cn \
      --argjson found "$found_dirs" \
      --argjson extra '{{EXTRA_CONTAINER_DIRECTORIES}}' \
      '$found + $extra | unique'


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


lambda-get-version:
    #!/usr/bin/env bash
    aws lambda get-alias \
        --function-name "$FUNCTION_NAME" --name "$ALIAS_NAME" \
        --query 'FunctionVersion' --output text


lambda-create-version:
    #!/usr/bin/env bash
    aws lambda update-function-code \
        --function-name "$FUNCTION_NAME" \
        --s3-bucket "$BUCKET_NAME" \
        --s3-key "$LAMBDA_ZIP_KEY" \
        --publish \
        --query 'Version' --output text


lambda-prepare-appspec:
    #!/usr/bin/env bash
    yq eval -i '
      .Resources[0].LambdaFunction.Properties.Name = env(FUNCTION_NAME) |
      .Resources[0].LambdaFunction.Properties.Alias = env(ALIAS_NAME) |
      .Resources[0].LambdaFunction.Properties.CurrentVersion = env(CURRENT_VERSION) |
      .Resources[0].LambdaFunction.Properties.TargetVersion = env(NEW_VERSION)
    ' $APP_SPEC_FILE
    cat $APP_SPEC_FILE


lambda-upload-bundle:
    #!/usr/bin/env bash
    just lambda-prepare-appspec

    LOCAL_APP_SPEC_ZIP="{{justfile_directory()}}/appspec-lambda.zip"
    TMPDIR="$(mktemp -d)"
    rm -f $LOCAL_APP_SPEC_ZIP
    cp "$APP_SPEC_FILE" "$TMPDIR/appspec.yml"
    zip -q -j $LOCAL_APP_SPEC_ZIP "$TMPDIR/appspec.yml"
    aws s3 cp $LOCAL_APP_SPEC_ZIP "s3://${BUCKET_NAME}/${APP_SPEC_KEY}"


lambda-get-function-arn:
    #!/usr/bin/env bash
    if [[ -z "$FUNCTION_NAME" ]]; then
        echo "❌ FUNCTION_NAME environment variable is not set."
        exit 1
    fi

    aws lambda get-function \
        --function-name $FUNCTION_NAME \
        --query 'Configuration.FunctionArn' \
        --output text


lambda-get-code-deploy-app:
    #!/usr/bin/env bash
    FUNCTION_ARN=$(just lambda-get-function-arn)
    aws lambda list-tags \
        --resource "$FUNCTION_ARN" \
        --query 'Tags.CodeDeployApplication' \
        --output text


lambda-get-code-deploy-group:
    #!/usr/bin/env bash
    FUNCTION_ARN=$(just lambda-get-function-arn)
    aws lambda list-tags \
        --resource "$FUNCTION_ARN" \
        --query 'Tags.CodeDeployGroup' \
        --output text


lambda-get-code-deploy-alarms:
    #!/usr/bin/env bash
    set -euo pipefail

    FUNCTION_ARN=$(just lambda-get-function-arn)

    aws lambda list-tags \
        --resource "$FUNCTION_ARN" \
        --query 'Tags' \
        --output json \
    | jq -c '
        to_entries
        | map(select(.key | test("^CodeDeployAlarm[0-9]+$")))
        | sort_by(.key | sub("^CodeDeployAlarm"; "") | tonumber)
        | map(.value)
      '


lambda-set-code-deploy-alarms:
    #!/usr/bin/env bash
    set -euo pipefail

    ALARMS_JSON=$(just lambda-get-code-deploy-alarms)

    # Convert JSON array to space-separated list
    ALARMS=$(echo "$ALARMS_JSON" | jq -r '.[]')

    # Reset each alarm to OK
    for ALARM_NAME in $ALARMS; do
        echo "Setting alarm to OK: $ALARM_NAME"
        aws cloudwatch set-alarm-state \
            --alarm-name "$ALARM_NAME" \
            --state-value OK \
            --state-reason "Reset by CI/CD"
    done


lambda-deploy:
    #!/usr/bin/env bash
    set -euo pipefail

    if [[ -z "$FUNCTION_NAME" ]]; then
        echo "❌ FUNCTION_NAME environment variable is not set."
        exit 1
    fi

    if [[ -z "$APP_SPEC_KEY" ]]; then
        echo "❌ APP_SPEC_KEY environment variable is not set."
        exit 1
    fi

    if [[ -z "$BUCKET_NAME" ]]; then
        echo "❌ BUCKET_NAME environment variable is not set."
        exit 1
    fi

    CODE_DEPLOY_APP_NAME=$(just lambda-get-code-deploy-app)
    CODE_DEPLOY_GROUP_NAME=$(just lambda-get-code-deploy-group)

    DEPLOYMENT_ID=$(aws deploy create-deployment \
        --application-name "$CODE_DEPLOY_APP_NAME" \
        --deployment-group-name "$CODE_DEPLOY_GROUP_NAME" \
        --s3-location bucket=$BUCKET_NAME,key=$APP_SPEC_KEY,bundleType=zip \
        --query "deploymentId" --output text)

    if [[ -z "$DEPLOYMENT_ID" || "$DEPLOYMENT_ID" == "None" ]]; then
        echo "❌ Failed to create deployment — no deployment ID returned."
        exit 1
    fi

    echo "🚀 Deployment started: $DEPLOYMENT_ID"
    echo "🏷️ CodeDeploy App: $CODE_DEPLOY_APP_NAME | Group: $CODE_DEPLOY_GROUP_NAME"
    echo "📦 AppSpec artifact: s3://$BUCKET_NAME/$APP_SPEC_KEY"
    echo "⏳ Monitoring deployment status…"

    MAX_ATTEMPTS=40       # ~10 minutes at 15s interval
    SLEEP_INTERVAL=15     # seconds

    for ((i=1; i<=MAX_ATTEMPTS; i++)); do
        STATUS=$(aws deploy get-deployment \
            --deployment-id "$DEPLOYMENT_ID" \
            --query "deploymentInfo.status" \
            --output text)

        echo "Attempt $i: Deployment status is $STATUS"

        if [[ "$STATUS" == "Succeeded" ]]; then
            echo "✅ Deployment $DEPLOYMENT_ID completed successfully."
            exit 0
        elif [[ "$STATUS" == "Failed" || "$STATUS" == "Stopped" ]]; then
            echo "❌ Deployment $DEPLOYMENT_ID failed or was stopped."
            aws deploy get-deployment \
                --deployment-id "$DEPLOYMENT_ID" \
                --query 'deploymentInfo.{Status:status, ErrorCode:errorInformation.code, ErrorMessage:errorInformation.message}' \
                --output table
            exit 1
    fi

    sleep "$SLEEP_INTERVAL"
    done

    echo "❌ Deployment $DEPLOYMENT_ID did not complete within expected time."
    exit 1


lambda-prune:
    #!/usr/bin/env bash
    set -euo pipefail

    if [[ -z "$ALIAS_NAME" ]]; then
        echo "❌ ALIAS_NAME environment variable is not set."
        exit 1
    fi

    if [[ -z "$FUNCTION_NAME" ]]; then
        echo "❌ FUNCTION_NAME environment variable is not set."
        exit 1
    fi

    if [[ -z "$AWS_REGION" ]]; then
        echo "❌ AWS_REGION environment variable is not set."
        exit 1
    fi

    live_version=$(aws lambda get-alias \
        --function-name "$FUNCTION_NAME" \
        --name "$ALIAS_NAME" \
        --region "$AWS_REGION" \
        | jq -r '.FunctionVersion')

    echo "Alias '$ALIAS_NAME' points to: ${live_version:-<none>}"
    versions=$(aws lambda list-versions-by-function \
        --function-name "$FUNCTION_NAME" \
        --region "$AWS_REGION" \
        | jq -r '.Versions[] | select(.Version != "$LATEST") | .Version' \
        | sort -nr)

    keep_newest=$(echo "$versions" | head -n "$KEEP")
    keep_set=$(printf "%s\n%s\n" "$keep_newest" "$live_version" | sort -u)
    to_delete=$(comm -23 <(echo "$versions" | sort -u) <(echo "$keep_set" | sort -u))

    echo "Keeping version(s):  $(echo "$keep_set" | tr '\n' ' ')"
    if [[ -z "${to_delete// }" ]]; then
        echo "Nothing to delete."
        exit 0
    fi
    for v in $to_delete; do
        echo "Deleting $FUNCTION_NAME:$v"
        aws lambda delete-function --function-name "$FUNCTION_NAME" --qualifier "$v" --region "$AWS_REGION"
    done


ecs-prepare-appspec:
    #!/usr/bin/env bash
    set -euo pipefail

    if [[ -z "${APP_SPEC_FILE:-}" ]]; then
        echo "❌ APP_SPEC_FILE environment variable is not set."
        exit 1
    fi

    if [[ -z "${TASK_DEFINITION_ARN:-}" ]]; then
        echo "❌ TASK_DEFINITION_ARN environment variable is not set."
        exit 1
    fi

    if [[ -z "${CONTAINER_NAME:-}" ]]; then
        echo "❌ CONTAINER_NAME environment variable is not set."
        exit 1
    fi

    if [[ -z "${CONTAINER_PORT:-}" ]]; then
        echo "❌ CONTAINER_PORT environment variable is not set."
        exit 1
    fi

    cp "{{justfile_directory()}}/appspec-ecs.yml" "$APP_SPEC_FILE"

    yq eval -i '
      .Resources[0].TargetService.Properties.TaskDefinition = env(TASK_DEFINITION_ARN) |
      .Resources[0].TargetService.Properties.LoadBalancerInfo.ContainerName = env(CONTAINER_NAME) |
      .Resources[0].TargetService.Properties.LoadBalancerInfo.ContainerPort = (env(CONTAINER_PORT) | tonumber)
    ' "$APP_SPEC_FILE"

    cat "$APP_SPEC_FILE"


ecs-upload-bundle:
    #!/usr/bin/env bash
    set -euo pipefail

    if [[ -z "${BUCKET_NAME:-}" ]]; then
        echo "❌ BUCKET_NAME environment variable is not set."
        exit 1
    fi

    if [[ -z "${APP_SPEC_KEY:-}" ]]; then
        echo "❌ APP_SPEC_KEY environment variable is not set."
        exit 1
    fi

    just ecs-prepare-appspec
    aws s3 cp "$APP_SPEC_FILE" "s3://${BUCKET_NAME}/${APP_SPEC_KEY}"


ecs-deploy:
    #!/usr/bin/env bash
    set -euo pipefail

    if [[ -z "${CODE_DEPLOY_APP_NAME:-}" ]]; then
        echo "❌ CODE_DEPLOY_APP_NAME environment variable is not set."
        exit 1
    fi

    if [[ -z "${CODE_DEPLOY_GROUP_NAME:-}" ]]; then
        echo "❌ CODE_DEPLOY_GROUP_NAME environment variable is not set."
        exit 1
    fi

    if [[ -z "${BUCKET_NAME:-}" ]]; then
        echo "❌ BUCKET_NAME environment variable is not set."
        exit 1
    fi

    if [[ -z "${APP_SPEC_KEY:-}" ]]; then
        echo "❌ APP_SPEC_KEY environment variable is not set."
        exit 1
    fi

    DEPLOYMENT_ID=$(aws deploy create-deployment \
        --application-name "$CODE_DEPLOY_APP_NAME" \
        --deployment-group-name "$CODE_DEPLOY_GROUP_NAME" \
        --revision revisionType=S3,s3Location="{bucket=$BUCKET_NAME,key=$APP_SPEC_KEY,bundleType=YAML}" \
        --query "deploymentId" --output text)

    if [[ -z "$DEPLOYMENT_ID" || "$DEPLOYMENT_ID" == "None" ]]; then
        echo "❌ Failed to create ECS deployment — no deployment ID returned."
        exit 1
    fi

    echo "🚀 Deployment started: $DEPLOYMENT_ID"
    echo "🏷️ CodeDeploy App: $CODE_DEPLOY_APP_NAME | Group: $CODE_DEPLOY_GROUP_NAME"
    echo "📦 AppSpec artifact: s3://$BUCKET_NAME/$APP_SPEC_KEY"
    echo "⏳ Monitoring deployment status…"

    MAX_ATTEMPTS=40
    SLEEP_INTERVAL=15

    for ((i=1; i<=MAX_ATTEMPTS; i++)); do
        STATUS=$(aws deploy get-deployment \
            --deployment-id "$DEPLOYMENT_ID" \
            --query "deploymentInfo.status" \
            --output text)

        echo "[$i/$MAX_ATTEMPTS] Status: $STATUS"

        if [[ "$STATUS" == "Succeeded" ]]; then
            echo "✅ ECS deployment $DEPLOYMENT_ID completed successfully."
            exit 0
        elif [[ "$STATUS" == "Failed" || "$STATUS" == "Stopped" ]]; then
            echo "❌ ECS deployment $DEPLOYMENT_ID failed or was stopped."
            aws deploy get-deployment \
                --deployment-id "$DEPLOYMENT_ID" \
                --query 'deploymentInfo.{Status:status, ErrorCode:errorInformation.code, ErrorMessage:errorInformation.message}' \
                --output table
            exit 1
        fi

        sleep "$SLEEP_INTERVAL"
    done

    echo "❌ ECS deployment $DEPLOYMENT_ID did not complete within expected time."
    exit 1


ecs-rolling-deploy:
    #!/usr/bin/env bash
    set -euo pipefail

    if [[ -z "${CLUSTER_NAME:-}" ]]; then
        echo "❌ CLUSTER_NAME environment variable is not set."
        exit 1
    fi

    if [[ -z "${SERVICE_NAME:-}" ]]; then
        echo "❌ SERVICE_NAME environment variable is not set."
        exit 1
    fi

    if [[ -z "${TASK_DEFINITION_ARN:-}" ]]; then
        echo "❌ TASK_DEFINITION_ARN environment variable is not set."
        exit 1
    fi

    echo "🚀 Starting ECS rolling deployment for $SERVICE_NAME on $CLUSTER_NAME"

    aws ecs update-service \
        --cluster "$CLUSTER_NAME" \
        --service "$SERVICE_NAME" \
        --task-definition "$TASK_DEFINITION_ARN" \
        >/dev/null

    aws ecs wait services-stable \
        --cluster "$CLUSTER_NAME" \
        --services "$SERVICE_NAME"

    echo "✅ ECS rolling deployment completed for $SERVICE_NAME"


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


frontend-check-version:
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

    aws s3 ls "s3://$BUCKET_NAME/frontend/$VERSION/frontend.zip" \
        && echo "✅ frontend.zip found at s3://$BUCKET_NAME/frontend/$VERSION/frontend.zip" \
        || (echo "❌ frontend.zip not found at s3://$BUCKET_NAME/frontend/$VERSION/frontend.zip" && exit 1)


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
    aws s3 sync "$TMPDIR/dist/" "s3://$WEBSITE_BUCKET/" --delete
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

