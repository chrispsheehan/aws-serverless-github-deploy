#!/usr/bin/env python3
from __future__ import annotations

import argparse
import importlib
import json
import os
import time
import uuid
from pathlib import Path
from typing import Callable

import boto3


class LambdaInvokeContext:
    function_name = "local_invoke_handler"
    function_version = "$LATEST"

    def __init__(self, aws_request_id: str = "local-invoke-request") -> None:
        self.aws_request_id = aws_request_id


def import_handler(import_path: str) -> Callable[[dict, object], dict]:
    module_name, attr_name = import_path.split(":", 1)
    module = importlib.import_module(module_name)
    return getattr(module, attr_name)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Invoke a Lambda-style handler locally.")
    parser.add_argument("handler_import_path", help="Import path in module:attribute form.")
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--event-json", help="Inline JSON event payload.")
    group.add_argument("--event-file", help="Path to a JSON event file.")
    group.add_argument("--sqs-queue-url", help="SQS-compatible queue URL to poll continuously.")
    parser.add_argument(
        "--request-id",
        default=os.getenv("LOCAL_INVOKE_REQUEST_ID", "local-invoke-request"),
        help="Request id for the local context.",
    )
    parser.add_argument(
        "--function-name",
        default=os.getenv("LOCAL_INVOKE_FUNCTION_NAME", "local_invoke_handler"),
        help="Function name for the local context.",
    )
    parser.add_argument(
        "--batch-size",
        type=int,
        default=int(os.getenv("LOCAL_SQS_BATCH_SIZE", "10")),
        help="Max number of messages to receive when polling SQS.",
    )
    parser.add_argument(
        "--wait-time-seconds",
        type=int,
        default=int(os.getenv("LOCAL_SQS_WAIT_TIME_SECONDS", "20")),
        help="Long-poll wait time for SQS receives.",
    )
    parser.add_argument(
        "--visibility-timeout",
        type=int,
        default=int(os.getenv("LOCAL_SQS_VISIBILITY_TIMEOUT", "30")),
        help="Visibility timeout for received SQS messages.",
    )
    parser.add_argument(
        "--idle-sleep-seconds",
        type=float,
        default=float(os.getenv("LOCAL_SQS_IDLE_SLEEP_SECONDS", "1")),
        help="Sleep duration after an empty receive.",
    )
    return parser.parse_args()


def build_sqs_event_record(message: dict, *, aws_region: str, event_source_arn: str) -> dict:
    return {
        "messageId": message["MessageId"],
        "receiptHandle": message["ReceiptHandle"],
        "body": message["Body"],
        "attributes": message.get("Attributes") or {},
        "messageAttributes": {
            key: {
                "stringValue": value.get("StringValue"),
                "binaryValue": value.get("BinaryValue"),
                "stringListValues": value.get("StringListValues") or [],
                "binaryListValues": value.get("BinaryListValues") or [],
                "dataType": value.get("DataType", "String"),
            }
            for key, value in (message.get("MessageAttributes") or {}).items()
        },
        "md5OfBody": message.get("MD5OfBody"),
        "eventSource": "aws:sqs",
        "eventSourceARN": event_source_arn,
        "awsRegion": aws_region,
    }


def poll_sqs(handler: Callable[[dict, object], dict], args: argparse.Namespace) -> int:
    aws_region = os.getenv("AWS_REGION", "eu-west-2")
    endpoint_url = os.getenv("AWS_ENDPOINT_URL_SQS")
    event_source_arn = os.getenv("LOCAL_SQS_EVENT_SOURCE_ARN", "arn:aws:sqs:local:000000000000:local-queue")

    sqs_client_kwargs = {"region_name": aws_region}
    if endpoint_url:
        sqs_client_kwargs["endpoint_url"] = endpoint_url
    sqs = boto3.client("sqs", **sqs_client_kwargs)

    try:
        while True:
            response = sqs.receive_message(
                QueueUrl=args.sqs_queue_url,
                MaxNumberOfMessages=args.batch_size,
                MessageAttributeNames=["All"],
                AttributeNames=["All"],
                WaitTimeSeconds=args.wait_time_seconds,
                VisibilityTimeout=args.visibility_timeout,
            )
            messages = response.get("Messages", [])
            if not messages:
                time.sleep(args.idle_sleep_seconds)
                continue

            event = {
                "Records": [
                    build_sqs_event_record(message, aws_region=aws_region, event_source_arn=event_source_arn)
                    for message in messages
                ]
            }
            context = LambdaInvokeContext(aws_request_id=str(uuid.uuid4()))
            context.function_name = args.function_name
            result = handler(event, context) or {}
            failed_ids = {
                item["itemIdentifier"]
                for item in result.get("batchItemFailures", [])
                if "itemIdentifier" in item
            }

            for message in messages:
                if message["MessageId"] in failed_ids:
                    continue
                sqs.delete_message(
                    QueueUrl=args.sqs_queue_url,
                    ReceiptHandle=message["ReceiptHandle"],
                )
    except KeyboardInterrupt:
        return 0


def main() -> int:
    args = parse_args()
    handler = import_handler(args.handler_import_path)
    if args.sqs_queue_url:
        return poll_sqs(handler, args)
    if args.event_file:
        event = json.loads(Path(args.event_file).read_text(encoding="utf-8"))
    else:
        event = json.loads(args.event_json)
    context = LambdaInvokeContext(aws_request_id=args.request_id)
    context.function_name = args.function_name
    handler(event, context)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
