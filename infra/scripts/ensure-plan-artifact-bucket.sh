#!/usr/bin/env bash
set -euo pipefail

bucket_name="${1:?bucket name is required}"
aws_region="${2:?aws region is required}"

if aws s3api head-bucket --bucket "$bucket_name" >/dev/null 2>&1; then
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
