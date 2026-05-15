#!/usr/bin/env bash
set -euo pipefail

bucket_name="${1:?bucket name is required}"
aws_region="${2:?aws region is required}"

if aws s3api head-bucket --bucket "$bucket_name" >/dev/null 2>&1; then
  exit 0
fi

if [ -t 0 ] && [ -t 1 ]; then
  printf "Artifact bucket '%s' does not exist. Create it in %s? [y/N] " "$bucket_name" "$aws_region" >&2
  read -r response
  case "$response" in
    [yY]|[yY][eE][sS]) ;;
    *)
      echo "Artifact bucket creation declined." >&2
      exit 1
      ;;
  esac
fi

if [ "$aws_region" = "us-east-1" ]; then
  aws s3api create-bucket --bucket "$bucket_name" >/dev/null
else
  aws s3api create-bucket --bucket "$bucket_name" --create-bucket-configuration "LocationConstraint=$aws_region" >/dev/null
fi
