#!/usr/bin/env bash
set -euo pipefail

bucket_name="${1:?bucket name is required}"
aws_region="${2:?aws region is required}"
retention_days="${3:-0}"
plan_prefix="${INFRA_PLAN_DIR:-terragrunt_plan/}"

if [[ "$plan_prefix" != */ ]]; then
  plan_prefix="${plan_prefix}/"
fi

ensure_lifecycle() {
  if [[ "$retention_days" =~ ^[0-9]+$ ]] && [ "$retention_days" -gt 0 ]; then
    aws s3api put-bucket-lifecycle-configuration \
      --bucket "$bucket_name" \
      --lifecycle-configuration "{
        \"Rules\": [
          {
            \"ID\": \"expire-plan-artifacts\",
            \"Status\": \"Enabled\",
            \"Filter\": {\"Prefix\": \"$plan_prefix\"},
            \"Expiration\": {\"Days\": $retention_days}
          }
        ]
      }" >/dev/null
    echo "Ensured plan artifact retention of ${retention_days} days on s3://${bucket_name}/${plan_prefix}"
  fi
}

if aws s3api head-bucket --bucket "$bucket_name" >/dev/null 2>&1; then
  ensure_lifecycle
  exit 0
fi

if [ -r /dev/tty ] && [ -w /dev/tty ]; then
  printf "Plan bucket '%s' does not exist. Create it in %s? [y/N] " "$bucket_name" "$aws_region" > /dev/tty
  read -r response < /dev/tty
  case "$response" in
    [yY]|[yY][eE][sS]) ;;
    *)
      echo "Plan bucket creation declined." >&2
      exit 1
      ;;
  esac
else
  echo "Plan bucket '$bucket_name' does not exist and no interactive terminal is available for confirmation." >&2
  echo "Create it manually or rerun from a terminal where Terragrunt hooks can prompt." >&2
  exit 1
fi

if [ "$aws_region" = "us-east-1" ]; then
  aws s3api create-bucket --bucket "$bucket_name" >/dev/null
else
  aws s3api create-bucket --bucket "$bucket_name" --create-bucket-configuration "LocationConstraint=$aws_region" >/dev/null
fi

ensure_lifecycle
