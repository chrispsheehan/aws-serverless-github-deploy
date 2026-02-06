_default:
    just --list


PROJECT_DIR := justfile_directory()
LAMBDA_DIR := "lambdas"


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
    git branch --set-upstream-to=origin/main {{ name }}
    git pull
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


check-version:
    #!/usr/bin/env bash
    set -euo pipefail

    FULL_BUCKET_NAME="$BUCKET_NAME/$VERSION/"

    if ! aws s3api head-bucket --bucket "$BUCKET_NAME" >/dev/null 2>&1; then
        echo "❌ The bucket '$BUCKET_NAME' does not exist or is inaccessible."
        exit 1
    fi

    if ! aws s3 ls "$FULL_BUCKET_NAME" >/dev/null 2>&1; then
        echo "❌ The subpath '$VERSION' does not exist in bucket '$BUCKET_NAME'."
        exit 1
    fi

    FILES=$(aws s3 ls $FULL_BUCKET_NAME --recursive | wc -l | xargs)
    if [ -n "$FILES" ]; then
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

    FULL_BUCKET_PATH="s3://$BUCKET_NAME/$VERSION/"

    aws s3api head-bucket --bucket "$BUCKET_NAME" >/dev/null
    aws s3 ls "$FULL_BUCKET_PATH" >/dev/null

    aws s3 ls "$FULL_BUCKET_PATH" --recursive \
      | awk '{print $4}' \
      | xargs -n1 basename \
      | sed 's/\.[^.]*$//' \
      | grep -v 'appspec' \
      | jq -R . \
      | jq -s -c .


lambda-get-directories:
    #!/usr/bin/env bash
    set -euo pipefail
    find "{{LAMBDA_DIR}}" -mindepth 1 -maxdepth 1 -type d \
      | xargs -I{} basename "{}" \
      | jq -R . \
      | jq -s -c .


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
    echo "📤 Uploading $LAMBDA_ZIP to s3://$BUCKET_NAME/$VERSION/$LAMBDA_NAME.zip"

    aws s3 cp "$LAMBDA_ZIP" "s3://$BUCKET_NAME/$VERSION/$LAMBDA_NAME.zip" \
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

    LOCAL_APP_SPEC_ZIP="{{justfile_directory()}}/appspec.zip"
    rm -f $LOCAL_APP_SPEC_ZIP
    zip -q -j $LOCAL_APP_SPEC_ZIP $APP_SPEC_FILE
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

    echo "🚀 Deployment started: $DEPLOYMENT_ID"
    echo "🏷️  CodeDeploy App: $CODE_DEPLOY_APP_NAME | Group: $CODE_DEPLOY_GROUP_NAME"
    echo "📦 AppSpec artifact: s3://$BUCKET_NAME/$APP_SPEC_KEY"
    echo "⏳ Monitoring deployment status…"

    if [[ -z "$DEPLOYMENT_ID" || "$DEPLOYMENT_ID" == "None" ]]; then
        echo "❌ Failed to create deployment — no deployment ID returned."
        exit 1
    fi

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


test-api-deploy-500s:
    #!/usr/bin/env bash
    set -euo pipefail

    if [[ -z "$API_URL" ]]; then
        echo "❌ API_URL environment variable is not set."
        exit 1
    fi

    echo "Sending requests to $API_URL to trigger 500 errors..."

    END=$((SECONDS+180))

    while [ $SECONDS -lt $END ]; do
        curl -s -o /dev/null "$API_URL/error"
    done

    echo "Finished sending requests."


test-send-dlq-messages:
    #!/usr/bin/env bash
    set -euo pipefail

    if [[ -z "$SQS_DLQ_QUEUE_URL" ]]; then
        echo "❌ SQS_DLQ_QUEUE_URL environment variable is not set."
        exit 1
    fi

    if [[ -z "$AWS_REGION" ]]; then
        echo "❌ AWS_REGION environment variable is not set."
        exit 1
    fi

    echo "Sending messages to SQS DLQ at $SQS_DLQ_QUEUE_URL..."

    for i in {1..10}; do
        aws sqs send-message --region $AWS_REGION --queue-url "$SQS_DLQ_QUEUE_URL" --message-body "Test message $i"
    done

    echo "Finished sending messages."