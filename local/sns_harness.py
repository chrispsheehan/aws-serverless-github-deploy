#!/usr/bin/env python3
from __future__ import annotations

# Local-only SNS publish shim.
# This is not a full SNS emulator. It only supports the Publish call shape used
# by lambda_api and fans those messages out to the configured local SQS queues.

import os
import uuid
from http.server import BaseHTTPRequestHandler, HTTPServer
from urllib.parse import parse_qs
from xml.sax.saxutils import escape

import boto3


AWS_REGION = os.getenv("AWS_REGION", "eu-west-2")
PORT = int(os.getenv("LOCAL_SNS_HARNESS_PORT", "9911"))
QUEUE_URLS = [
    queue_url.strip()
    for queue_url in os.getenv("LOCAL_WORKER_QUEUE_URLS", "").split(",")
    if queue_url.strip()
]
_sqs_client_kwargs = {"region_name": AWS_REGION}
if os.getenv("AWS_ENDPOINT_URL_SQS", "").strip():
    _sqs_client_kwargs["endpoint_url"] = os.getenv("AWS_ENDPOINT_URL_SQS", "").strip()
SQS = boto3.client("sqs", **_sqs_client_kwargs)


def parse_message_attributes(params: dict[str, list[str]]) -> dict[str, dict[str, str]]:
    entries: dict[str, dict[str, str]] = {}
    for key, values in params.items():
        if not key.startswith("MessageAttributes.entry."):
            continue
        parts = key.split(".")
        if len(parts) < 5:
            continue
        entry = entries.setdefault(parts[2], {})
        entry[parts[4]] = values[0]

    message_attributes: dict[str, dict[str, str]] = {}
    for entry in entries.values():
        name = entry.get("Name")
        if not name:
            continue
        message_attributes[name] = {
            "DataType": entry.get("DataType", "String"),
            "StringValue": entry.get("StringValue", ""),
        }
    return message_attributes


def publish_response_xml(message_id: str) -> bytes:
    request_id = str(uuid.uuid4())
    body = f"""<?xml version="1.0"?>
<PublishResponse xmlns="http://sns.amazonaws.com/doc/2010-03-31/">
  <PublishResult>
    <MessageId>{escape(message_id)}</MessageId>
  </PublishResult>
  <ResponseMetadata>
    <RequestId>{escape(request_id)}</RequestId>
  </ResponseMetadata>
</PublishResponse>
"""
    return body.encode("utf-8")


class Handler(BaseHTTPRequestHandler):
    def do_POST(self) -> None:  # noqa: N802
        if not QUEUE_URLS:
            self.send_error(500, "LOCAL_WORKER_QUEUE_URLS is not configured")
            return

        content_length = int(self.headers.get("Content-Length", "0") or "0")
        params = parse_qs(self.rfile.read(content_length).decode("utf-8"), keep_blank_values=True)
        if (params.get("Action") or [""])[0] != "Publish":
            self.send_error(400, "Only Publish is supported")
            return

        message = (params.get("Message") or [""])[0]
        message_attributes = parse_message_attributes(params)
        for queue_url in QUEUE_URLS:
            SQS.send_message(
                QueueUrl=queue_url,
                MessageBody=message,
                MessageAttributes=message_attributes,
            )
        encoded = publish_response_xml(str(uuid.uuid4()))

        self.send_response(200)
        self.send_header("Content-Type", "text/xml; charset=utf-8")
        self.send_header("Content-Length", str(len(encoded)))
        self.end_headers()
        self.wfile.write(encoded)

    def log_message(self, format: str, *args) -> None:
        return


def main() -> int:
    server = HTTPServer(("0.0.0.0", PORT), Handler)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        return 0
    finally:
        server.server_close()


if __name__ == "__main__":
    raise SystemExit(main())
