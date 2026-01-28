import json
import os
import uuid
import time

ENV_ID = str(uuid.uuid4())[:8]
BOOT_TIME_MS = int(time.time() * 1000)

DEBUG_DELAY_MS = int(os.getenv("DEBUG_DELAY_MS", "0"))


def lambda_handler(event, context):
    print("Received event:", json.dumps(event))

    # Optional delay to force concurrency during testing
    if DEBUG_DELAY_MS > 0:
        time.sleep(DEBUG_DELAY_MS / 1000.0)

    # --- Error endpoint: /fail or /error returns 500 ---
    path = event.get("rawPath") or event.get("path") or ""
    if path in ("/fail", "/error", "/health/fail"):
        error_body = {
            "message": "Forced failure for testing",
            "env_id": ENV_ID,
            "request_id": context.aws_request_id,
        }
        return {
            "statusCode": 500,
            "headers": {
                "Content-Type": "application/json",
                "X-Env-Id": ENV_ID,
            },
            "body": json.dumps(error_body),
        }

    # Normal success response
    body = {
        "message": "Hello from Lambda!",
        "env_id": ENV_ID,
        "boot_time_ms": BOOT_TIME_MS,
        "request_id": context.aws_request_id,
        "function_name": context.function_name,
        "function_version": context.function_version,
        "debug_delay_ms": DEBUG_DELAY_MS,
    }

    response = {
        "statusCode": 200,
        "headers": {
            "Content-Type": "application/json",
            "X-Env-Id": ENV_ID,
        },
        "body": json.dumps(body),
    }

    return response
