import boto3
import json
import os
import time

from opentelemetry.trace import SpanKind

from db_shared import connect
from ecs_tracing import extract_context, start_span
from runtime_logging import get_logger

QUEUE_URL    = os.environ['AWS_SQS_QUEUE_URL']
AWS_REGION   = os.environ['AWS_REGION']
POLL_TIMEOUT = int(os.getenv("POLL_TIMEOUT", "60"))
HEARTBEAT_FILE = os.getenv("HEARTBEAT_FILE", "/tmp/worker-heartbeat")

sqs = boto3.client('sqs', region_name=AWS_REGION)
logger = get_logger(__name__)


def write_heartbeat():
    with open(HEARTBEAT_FILE, "w", encoding="utf-8") as heartbeat:
        heartbeat.write(str(int(time.time())))


def process_message(msg):
    ctx = extract_context(lambda key: message_attribute_value(msg, key))
    with start_span(
        "worker.process_message",
        kind=SpanKind.CONSUMER,
        context=ctx,
        attributes={
            "messaging.system": "aws.sqs",
            "messaging.operation": "process",
            "messaging.destination.name": QUEUE_URL,
            "messaging.message.id": msg["MessageId"],
        },
    ):
        job_id = extract_job_id(msg["Body"])
        persist_message(msg["MessageId"], msg["Body"], job_id)
        logger.info(
            "ecs_worker_message_processed",
            extra={
                "event": "ecs_worker_message_processed",
                "message_id": msg["MessageId"],
                "job_id": job_id,
                "persisted_to_postgres": True,
                "body_preview": msg["Body"][:200],
                "queue_url": QUEUE_URL,
                "trace_attributes": trace_attributes(msg),
            },
        )


def extract_job_id(body):
    try:
        payload = json.loads(body)
    except json.JSONDecodeError:
        return None
    return payload.get("job_id") if isinstance(payload, dict) else None


def persist_message(message_id, body, job_id):
    with start_span(
        "db.persist_message",
        kind=SpanKind.CLIENT,
        attributes={
            "db.system": "postgresql",
            "db.operation": "insert",
            "db.namespace": os.getenv("DB_NAME", ""),
            "messaging.message.id": message_id,
        },
    ):
        with connect() as connection:
            with connection.cursor() as cursor:
                cursor.execute(
                    """
                    insert into worker_messages (sqs_message_id, job_id, message_body)
                    values (%s, %s, %s)
                    on conflict (sqs_message_id) do nothing
                    """,
                    (message_id, job_id, body),
                )


def message_attribute_value(message, key):
    value = (message.get("MessageAttributes") or {}).get(key, {})
    return value.get("StringValue")


def trace_attributes(message):
    return {
        key: value
        for key in (
            "traceparent",
            "tracestate",
            "x-amzn-trace-id",
            "correlation_id",
        )
        if (value := message_attribute_value(message, key))
    }


def poll():
    with start_span(
        "sqs.receive_message",
        kind=SpanKind.CLIENT,
        attributes={
            "messaging.system": "aws.sqs",
            "messaging.operation": "receive",
            "messaging.destination.name": QUEUE_URL,
        },
    ) as span:
        response = sqs.receive_message(
            QueueUrl=QUEUE_URL,
            MaxNumberOfMessages=10,
            MessageAttributeNames=["All"],
            WaitTimeSeconds=20,
            VisibilityTimeout=30,
        )
        messages = response.get('Messages', [])
        span.set_attribute("messaging.batch.message_count", len(messages))
    if not messages:
        logger.info(
            "ecs_worker_no_messages",
            extra={
                "event": "ecs_worker_no_messages",
                "queue_url": QUEUE_URL,
            },
        )
        return
    logger.info(
        "ecs_worker_batch_received",
        extra={
            "event": "ecs_worker_batch_received",
            "queue_url": QUEUE_URL,
            "message_count": len(messages),
        },
    )
    for msg in messages:
        try:
            process_message(msg)
            with start_span(
                "sqs.delete_message",
                kind=SpanKind.CLIENT,
                attributes={
                    "messaging.system": "aws.sqs",
                    "messaging.operation": "delete",
                    "messaging.destination.name": QUEUE_URL,
                    "messaging.message.id": msg["MessageId"],
                },
            ):
                sqs.delete_message(QueueUrl=QUEUE_URL, ReceiptHandle=msg['ReceiptHandle'])
        except Exception:
            logger.exception(
                "ecs_worker_message_failed",
                extra={
                    "event": "ecs_worker_message_failed",
                    "message_id": msg["MessageId"],
                    "queue_url": QUEUE_URL,
                },
            )


if __name__ == "__main__":
    logger.info(
        "ecs_worker_startup",
        extra={
            "event": "ecs_worker_startup",
            "queue_url": QUEUE_URL,
            "poll_timeout_seconds": POLL_TIMEOUT,
            "heartbeat_file": HEARTBEAT_FILE,
        },
    )
    write_heartbeat()
    while True:
        poll()
        write_heartbeat()
        time.sleep(POLL_TIMEOUT)
