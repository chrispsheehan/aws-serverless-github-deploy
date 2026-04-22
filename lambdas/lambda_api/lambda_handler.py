import json
import os
import uuid
import time

import boto3

from lambda_shared import get_logger, json_response

ENV_ID = str(uuid.uuid4())[:8]
BOOT_TIME_MS = int(time.time() * 1000)

DEBUG_DELAY_MS = int(os.getenv("DEBUG_DELAY_MS", "0"))
WORKER_TOPIC_ARN = os.getenv("WORKER_TOPIC_ARN", "").strip()
WORKER_TOPIC_NAME = os.getenv("WORKER_TOPIC_NAME", "").strip()
logger = get_logger(__name__)

_sns = boto3.client("sns", region_name=os.getenv("AWS_REGION", "eu-west-2"))


def _json_body(event):
    body = event.get("body") or ""
    if event.get("isBase64Encoded"):
        raise ValueError("Base64-encoded request bodies are not supported for POST /messages")
    if not body:
        raise ValueError("Request body is required")
    payload = json.loads(body)
    if not isinstance(payload, dict):
        raise ValueError("Request body must be a JSON object")
    return payload


def _publish_worker_message(payload):
    if not WORKER_TOPIC_ARN:
        raise RuntimeError("Missing WORKER_TOPIC_ARN")

    trace_attributes = _trace_message_attributes(payload.get("_trace", {}))
    logger.info(
        "lambda_api_publish_attempt",
        extra={
            "event": "lambda_api_publish_attempt",
            "topic_name": WORKER_TOPIC_NAME,
            "topic_arn_present": bool(WORKER_TOPIC_ARN),
            "message_type": payload.get("type"),
            "job_id": payload.get("job_id"),
            "trace_attribute_keys": sorted(trace_attributes.keys()),
        },
    )
    response = _sns.publish(
        TopicArn=WORKER_TOPIC_ARN,
        Message=json.dumps(payload),
        MessageAttributes=trace_attributes,
    )
    return response["MessageId"]


def _trace_message_attributes(trace_payload):
    attributes = {}
    for key in ("traceparent", "tracestate", "x-amzn-trace-id", "correlation_id"):
      value = trace_payload.get(key)
      if value:
        attributes[key] = {
          "DataType": "String",
          "StringValue": value,
        }
    return attributes


def _trace_payload(event, context):
    headers = {str(key).lower(): value for key, value in (event.get("headers") or {}).items()}
    trace_payload = {
        "correlation_id": context.aws_request_id,
    }

    for key in ("traceparent", "tracestate"):
        value = headers.get(key)
        if value:
            trace_payload[key] = value

    xray_trace_id = os.getenv("_X_AMZN_TRACE_ID", "").strip()
    if xray_trace_id:
        trace_payload["x-amzn-trace-id"] = xray_trace_id

    return trace_payload


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

    if path == "/messages" and event.get("requestContext", {}).get("http", {}).get("method") == "POST":
        try:
            payload = _json_body(event)
            payload["_trace"] = _trace_payload(event, context)
            logger.info(
                "lambda_api_publish_request",
                extra={
                    "event": "lambda_api_publish_request",
                    "request_id": context.aws_request_id,
                    "path": path,
                    "message_type": payload.get("type"),
                    "job_id": payload.get("job_id"),
                    "payload_keys": sorted(payload.keys()),
                    "has_location": "location" in payload,
                    "has_auth": "auth" in payload,
                },
            )
            message_id = _publish_worker_message(payload)
        except (ValueError, json.JSONDecodeError) as exc:
            logger.error(
                "lambda_api_publish_invalid_request",
                extra={
                    "event": "lambda_api_publish_invalid_request",
                    "request_id": context.aws_request_id,
                    "path": path,
                    "error": str(exc),
                },
            )
            return json_response(
                400,
                {
                    "ok": False,
                    "error": str(exc),
                },
            )
        except Exception as exc:
            logger.exception(
                "lambda_api_publish_failed",
                extra={
                    "event": "lambda_api_publish_failed",
                    "request_id": context.aws_request_id,
                    "path": path,
                    "topic_name": WORKER_TOPIC_NAME,
                    "message_type": payload.get("type") if "payload" in locals() else None,
                    "job_id": payload.get("job_id") if "payload" in locals() else None,
                    "error": str(exc),
                },
            )
            return json_response(
                500,
                {
                    "ok": False,
                    "error": "Failed to publish message",
                },
            )

        logger.info(
            "lambda_api_message_published",
            extra={
                "event": "lambda_api_message_published",
                "request_id": context.aws_request_id,
                "path": path,
                "topic_name": WORKER_TOPIC_NAME,
                "message_id": message_id,
                "trace": payload.get("_trace", {}),
            },
        )
        return json_response(
            202,
            {
                "ok": True,
                "message_id": message_id,
                "topic_name": WORKER_TOPIC_NAME,
                "published": True,
                "correlation_id": payload["_trace"]["correlation_id"],
            },
        )

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
