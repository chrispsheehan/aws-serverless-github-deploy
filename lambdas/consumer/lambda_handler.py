import json
from typing import List, Dict

CHUNK_SIZE = 50


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
    print({
        "message_id": record["messageId"],
        "body_preview": body[:200]
    })


def process_chunk(records: List[Dict]) -> List[str]:
    """
    Process a chunk of messages.
    Returns a list of messageIds that failed.
    """
    failed_message_ids = []

    for record in records:
        try:
            process_message(record)
        except Exception as exc:
            print(f"Failed processing message {record['messageId']}: {exc}")
            failed_message_ids.append(record["messageId"])

    return failed_message_ids


def lambda_handler(event, context):
    """
    AWS Lambda entry point.
    Uses partial batch response so only failed messages are retried.
    """
    records = event.get("Records", [])
    batch_item_failures = []

    for records_chunk in chunk(records, CHUNK_SIZE):
        failed_ids = process_chunk(records_chunk)

        for message_id in failed_ids:
            batch_item_failures.append({
                "itemIdentifier": message_id
            })

    return {
        "batchItemFailures": batch_item_failures
    }
