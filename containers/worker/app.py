import boto3
import json
import os
import time

from opentelemetry.trace import SpanKind

from db_shared import connect
from ecs_tracing import start_span

QUEUE_URL    = os.environ['AWS_SQS_QUEUE_URL']
AWS_REGION   = os.environ['AWS_REGION']
POLL_TIMEOUT = int(os.getenv("POLL_TIMEOUT", "60"))
HEARTBEAT_FILE = os.getenv("HEARTBEAT_FILE", "/tmp/worker-heartbeat")

sqs = boto3.client('sqs', region_name=AWS_REGION)


def write_heartbeat():
    with open(HEARTBEAT_FILE, "w", encoding="utf-8") as heartbeat:
        heartbeat.write(str(int(time.time())))


def process_message(msg):
    with start_span(
        "worker.process_message",
        kind=SpanKind.CONSUMER,
        attributes={
            "messaging.system": "aws.sqs",
            "messaging.operation": "process",
            "messaging.destination.name": QUEUE_URL,
            "messaging.message.id": msg["MessageId"],
        },
    ):
        job_id = extract_job_id(msg["Body"])
        persist_message(msg["MessageId"], msg["Body"], job_id)
        print({
            "message_id": msg['MessageId'],
            "job_id": job_id,
            "persisted_to_postgres": True,
            "body": msg['Body'][:200],
        })


def extract_job_id(body):
    try:
        payload = json.loads(body)
    except json.JSONDecodeError:
        return None
    return payload.get("job_id") if isinstance(payload, dict) else None


def persist_message(message_id, body, job_id):
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
            WaitTimeSeconds=20,
            VisibilityTimeout=30,
        )
        messages = response.get('Messages', [])
        span.set_attribute("messaging.batch.message_count", len(messages))
    if not messages:
        print("No messages")
        return
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
        except Exception as e:
            print(f"Failed {msg['MessageId']}: {e}")


if __name__ == "__main__":
    print(f"Starting SQS poller for {QUEUE_URL}")
    write_heartbeat()
    while True:
        poll()
        write_heartbeat()
        time.sleep(POLL_TIMEOUT)
