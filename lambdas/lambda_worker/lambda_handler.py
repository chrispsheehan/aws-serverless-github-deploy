import os
import time
from typing import List, Dict

from lambda_shared import get_logger

CHUNK_SIZE = 5
DEBUG_DELAY_MS = int(os.getenv("DEBUG_DELAY_MS", "0"))
logger = get_logger(__name__)

def chunk(items: List[Dict], size: int):
    """Yield successive chunks from a list."""
    for i in range(0, len(items), size):
        yield items[i:i + size]


def process_message(record: Dict):
    """
    Process a single SQS message.
    Raise an exception to mark it as failed.
    """
    body = record["body"]

    # If your messages are JSON:
    # payload = json.loads(body)

    # TODO: your business logic here
    logger.info(
        "lambda_worker_process_message",
        extra={
            "event": "lambda_worker_process_message",
            "message_id": record["messageId"],
            "body_preview": body[:200],
        },
    )


def process_chunk(records: List[Dict]) -> List[str]:
    """
    Process a chunk of messages.
    Returns a list of messageIds that failed.
    """
    failed_message_ids = []

    for record in records:
        try:
            process_message(record)
            # Optional delay to force concurrency during testing
            if DEBUG_DELAY_MS > 0:
                time.sleep(DEBUG_DELAY_MS / 1000.0)
        except Exception:
            logger.exception(
                "lambda_worker_process_message_failed",
                extra={
                    "event": "lambda_worker_process_message_failed",
                    "message_id": record["messageId"],
                },
            )
            failed_message_ids.append(record["messageId"])

    return failed_message_ids


def lambda_handler(event, context):
    """
    AWS Lambda entry point.
    Uses partial batch response so only failed messages are retried.
    """
    records = event.get("Records", [])
    batch_item_failures = []

    logger.info(
        "lambda_worker_batch_start",
        extra={
            "event": "lambda_worker_batch_start",
            "request_id": context.aws_request_id,
            "record_count": len(records),
            "chunk_size": CHUNK_SIZE,
        },
    )

    for records_chunk in chunk(records, CHUNK_SIZE):
        failed_ids = process_chunk(records_chunk)

        for message_id in failed_ids:
            batch_item_failures.append({
                "itemIdentifier": message_id
            })

    response = {
        "batchItemFailures": batch_item_failures
    }

    logger.info(
        "lambda_worker_batch_complete",
        extra={
            "event": "lambda_worker_batch_complete",
            "request_id": context.aws_request_id,
            "record_count": len(records),
            "failure_count": len(batch_item_failures),
            "failed_message_ids": [item["itemIdentifier"] for item in batch_item_failures],
        },
    )

    return response
