_default:
    just --list


PROJECT_DIR := justfile_directory()

clean-terragrunt-cache:
    @echo "Cleaning up .terraform directories in {{PROJECT_DIR}}..."
    find {{PROJECT_DIR}} -type d -name ".terraform" -exec rm -rf {} +
    @echo "Cleaning up .terraform.lock.hcl files in {{PROJECT_DIR}}..."
    find {{PROJECT_DIR}} -type f -name ".terraform.lock.hcl" -exec rm -f {} +
    @echo "Cleaning up .terragrunt-cache directories in {{PROJECT_DIR}}..."
    find {{PROJECT_DIR}} -type d -name ".terragrunt-cache" -exec rm -rf {} +
    @echo "Cleaning up terragrunt-debug.tfvars.json files in {{PROJECT_DIR}}..."
    find {{PROJECT_DIR}} -type f -name "terragrunt-debug.tfvars.json" -exec rm -f {} +


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


backend-upload:
    #!/usr/bin/env bash
    set -euo pipefail

    BACKEND_DIR="{{justfile_directory()}}/backend"

    echo "📤 Uploading .zip files from $BACKEND_DIR to s3://$BUCKET_NAME/$VERSION/"

    aws s3 cp "$BACKEND_DIR" "s3://$BUCKET_NAME/$VERSION/" \
        --recursive \
        --exclude "*" \
        --include "*.zip" \
        --storage-class STANDARD


backend-build:
    #!/usr/bin/env bash
    set -euo pipefail

    python3 -m venv venv
    source venv/bin/activate

    BACKEND_DIR="{{justfile_directory()}}/backend"
    BACKEND_BUILD_DIR="$BACKEND_DIR/build"

    echo "🔄 Cleaning previous builds..."
    rm -rf $BACKEND_BUILD_DIR

    for dir in $(find "$BACKEND_DIR" -mindepth 1 -maxdepth 1 -type d); do
        app_name=$(basename "$dir")
        echo "📦 Building $app_name Lambda..."
        mkdir -p "$BACKEND_BUILD_DIR/$app_name"
        pip install --target "$BACKEND_BUILD_DIR/$app_name" -r "$dir/requirements.txt"
        cp "$dir"/*.py "$BACKEND_BUILD_DIR/$app_name/"
        (
            cd "$BACKEND_BUILD_DIR/$app_name"
            zip -r "../../$app_name.zip" . > /dev/null
        )
        echo "✅ Done: backend/$app_name.zip"
    done

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


lambda-upload-bundle:
    #!/usr/bin/env bash
    rm -f $APP_SPEC_KEY
    zip -q $APP_SPEC_ZIP $APP_SPEC_FILE
    aws s3 cp $APP_SPEC_ZIP "s3://${BUCKET_NAME}/${APP_SPEC_KEY}"


lambda-deploy:
    #!/usr/bin/env bash
    DEPLOYMENT_ID=$(aws deploy create-deployment \
        --application-name "$CODE_DEPLOY_APP_NAME" \
        --deployment-group-name "$CODE_DEPLOY_GROUP_NAME" \
        --deployment-config-name CodeDeployDefault.LambdaCanary10Percent5Minutes \
        --s3-location bucket=$BUCKET_NAME,key=$APP_SPEC_KEY,bundleType=zip \
        --query "deploymentId" --output text)

    echo "🚀 Started deployment: $DEPLOYMENT_ID"

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

