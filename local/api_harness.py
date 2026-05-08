#!/usr/bin/env python3
from __future__ import annotations

import argparse
import importlib
import os
import uuid
from http.server import BaseHTTPRequestHandler, HTTPServer
from typing import Callable


class LambdaHttpContext:
    function_name = "local_http_handler"
    function_version = "$LATEST"

    def __init__(self, aws_request_id: str) -> None:
        self.aws_request_id = aws_request_id


def build_lambda_http_event(
    method: str,
    path: str,
    headers: dict[str, str] | None = None,
    body: str = "",
) -> dict:
    return {
        "rawPath": path,
        "path": path,
        "headers": headers or {},
        "body": body,
        "isBase64Encoded": False,
        "requestContext": {
            "http": {
                "method": method,
            }
        },
    }


def serve_lambda_http_handler(
    handler: Callable[[dict, object], dict],
    *,
    host: str = "0.0.0.0",
    port: int = 8080,
    context_factory: Callable[[str], object] = LambdaHttpContext,
) -> None:
    class Handler(BaseHTTPRequestHandler):
        def _handle(self) -> None:
            path = self.path.split("?", 1)[0]
            body = ""
            content_length = int(self.headers.get("Content-Length", "0") or "0")
            if content_length > 0:
                body = self.rfile.read(content_length).decode("utf-8")

            event = build_lambda_http_event(
                self.command,
                path,
                headers={key: value for key, value in self.headers.items()},
                body=body,
            )
            context = context_factory(str(uuid.uuid4()))
            response = handler(event, context)
            response_body = response.get("body", "")
            encoded = response_body.encode("utf-8")

            self.send_response(int(response.get("statusCode", 200)))
            for key, value in (response.get("headers") or {}).items():
                self.send_header(key, value)
            self.send_header("Content-Length", str(len(encoded)))
            self.end_headers()
            self.wfile.write(encoded)

        def do_GET(self) -> None:  # noqa: N802
            self._handle()

        def do_POST(self) -> None:  # noqa: N802
            self._handle()

        def log_message(self, format: str, *args) -> None:
            return

    server = HTTPServer((host, port), Handler)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        # watchfiles interrupts the running server process before restarting it.
        pass
    finally:
        server.server_close()


def import_handler(import_path: str) -> Callable[[dict, object], dict]:
    module_name, attr_name = import_path.split(":", 1)
    module = importlib.import_module(module_name)
    return getattr(module, attr_name)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Run a local HTTP harness for a Lambda-style handler.")
    parser.add_argument("handler_import_path", help="Import path in module:attribute form.")
    parser.add_argument(
        "--port",
        type=int,
        default=int(os.getenv("LOCAL_API_HARNESS_PORT", os.getenv("PORT", "8080"))),
        help="Port to bind the local HTTP server to.",
    )
    parser.add_argument("--host", default="0.0.0.0", help="Host interface to bind.")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    handler = import_handler(args.handler_import_path)
    serve_lambda_http_handler(handler, host=args.host, port=args.port)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
