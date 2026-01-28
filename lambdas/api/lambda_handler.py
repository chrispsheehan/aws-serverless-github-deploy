import json
import os
import uuid
import time

# Runs once per execution environment (cold start)
ENV_ID = str(uuid.uuid4())[:8]
BOOT_TIME_MS = int(time.time() * 1000)

def lambda_handler(event, context):
    print("Received event:", json.dumps(event))

    body = {
        "message": "Hello from Lambda!",
        "env_id": ENV_ID,
        "boot_time_ms": BOOT_TIME_MS,
        "request_id": context.aws_request_id,
        "function_name": context.function_name,
        "function_version": context.function_version,
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
