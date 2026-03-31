import boto3
import os
import time

QUEUE_URL    = os.environ['AWS_SQS_QUEUE_URL']
AWS_REGION   = os.environ['AWS_REGION']
POLL_TIMEOUT = int(os.getenv("POLL_TIMEOUT", "60"))

sqs = boto3.client('sqs', region_name=AWS_REGION)


def process_message(msg):
    # TODO: implement business logic
    print({"message_id": msg['MessageId'], "body": msg['Body'][:200]})


def poll():
    response = sqs.receive_message(
        QueueUrl=QUEUE_URL,
        MaxNumberOfMessages=10,
        WaitTimeSeconds=20,
        VisibilityTimeout=30,
    )
    messages = response.get('Messages', [])
    if not messages:
        print("No messages")
        return
    for msg in messages:
        try:
            process_message(msg)
            sqs.delete_message(QueueUrl=QUEUE_URL, ReceiptHandle=msg['ReceiptHandle'])
        except Exception as e:
            print(f"Failed {msg['MessageId']}: {e}")


if __name__ == "__main__":
    print(f"Starting SQS poller for {QUEUE_URL}")
    while True:
        poll()
        time.sleep(POLL_TIMEOUT)
