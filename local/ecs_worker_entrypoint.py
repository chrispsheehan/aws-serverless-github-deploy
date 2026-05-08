#!/usr/bin/env python3
from __future__ import annotations

import os
import runpy

import boto3


_original_boto3_client = boto3.client
_original_session_client = boto3.session.Session.client


def _patch_kwargs(service_name: str, kwargs: dict) -> dict:
    if service_name != "sqs":
        return kwargs
    endpoint_url = kwargs.get("endpoint_url") or os.getenv("AWS_ENDPOINT_URL_SQS")
    if endpoint_url:
        kwargs["endpoint_url"] = endpoint_url
    return kwargs


def _patched_client(service_name: str, *args, **kwargs):
    return _original_boto3_client(service_name, *args, **_patch_kwargs(service_name, kwargs))


def _patched_session_client(self, service_name: str, *args, **kwargs):
    return _original_session_client(self, service_name, *args, **_patch_kwargs(service_name, kwargs))


def main() -> int:
    boto3.client = _patched_client
    boto3.session.Session.client = _patched_session_client
    runpy.run_path("/workspace/containers/worker/app.py", run_name="__main__")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
