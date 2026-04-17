import json
import os
import uuid
import time

from lambda_shared import get_logger

ENV_ID = str(uuid.uuid4())[:8]
BOOT_TIME_MS = int(time.time() * 1000)

DEBUG_DELAY_MS = int(os.getenv("DEBUG_DELAY_MS", "0"))
logger = get_logger(__name__)


def lambda_handler(event, context):
    path = event.get("rawPath") or event.get("path") or ""
    logger.info(
        "lambda_api_request",
        extra={
            "event": "lambda_api_request",
            "request_id": context.aws_request_id,
            "path": path,
            "http_method": event.get("requestContext", {}).get("http", {}).get("method"),
            "request_event": event,
        },
    )

    # Optional delay to force concurrency during testing
    if DEBUG_DELAY_MS > 0:
        time.sleep(DEBUG_DELAY_MS / 1000.0)

    # --- Error endpoint: /fail or /error returns 500 ---
    if path in ("/fail", "/error", "/health/fail"):
        logger.error(
            "lambda_api_forced_failure",
            extra={
                "event": "lambda_api_forced_failure",
                "request_id": context.aws_request_id,
                "path": path,
            },
        )
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

    logger.info(
        "lambda_api_response",
        extra={
            "event": "lambda_api_response",
            "request_id": context.aws_request_id,
            "status_code": response["statusCode"],
            "path": path,
        },
    )

    return response
