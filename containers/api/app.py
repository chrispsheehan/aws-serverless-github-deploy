import json
import os
import socket
from http.server import BaseHTTPRequestHandler, HTTPServer

from opentelemetry.trace import SpanKind

from ecs_tracing import extract_context, start_span
from runtime_logging import get_logger


HOST = "0.0.0.0"
PORT = int(os.getenv("PORT", "80"))
ROOT_PATH = os.getenv("ROOT_PATH", "")
SERVICE_NAME = os.getenv("AWS_SERVICE_NAME", "ecs-service-api")
IMAGE = os.getenv("IMAGE", "unknown")
logger = get_logger(__name__)


def _normalize_root_path(root_path: str) -> str:
    if not root_path:
        return ""
    return root_path if root_path.startswith("/") else f"/{root_path}"


ROOT_PATH_PREFIX = _normalize_root_path(ROOT_PATH.rstrip("/"))


def route_for(path: str) -> str:
    if ROOT_PATH_PREFIX and path.startswith(ROOT_PATH_PREFIX):
        trimmed = path[len(ROOT_PATH_PREFIX):]
        return trimmed or "/"
    return path or "/"


class Handler(BaseHTTPRequestHandler):
    server_version = "BlueGreenAPI/1.0"

    def _write_json(self, status: int, body: dict) -> None:
        encoded = json.dumps(body).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(encoded)))
        self.end_headers()
        self.wfile.write(encoded)

    def do_GET(self) -> None:  # noqa: N802
        path = self.path.split("?", 1)[0]
        route = route_for(path)
        ctx = extract_context(lambda key: self.headers.get(key))
        request_id = self.headers.get("X-Request-Id", "")

        logger.info(
            "ecs_api_request",
            extra={
                "event": "ecs_api_request",
                "http_method": self.command,
                "path": path,
                "route": route,
                "host": self.headers.get("Host", ""),
                "user_agent": self.headers.get("User-Agent", ""),
                "request_id": request_id,
                "service": SERVICE_NAME,
            },
        )

        with start_span(
            name=f"{self.command} {route}",
            context=ctx,
            kind=SpanKind.SERVER,
            attributes={
                "http.method": self.command,
                "http.target": path,
                "http.route": route,
                "http.host": self.headers.get("Host", ""),
                "http.user_agent": self.headers.get("User-Agent", ""),
            },
        ) as span:
            if route == "/health":
                span.set_attribute("http.status_code", 200)
                logger.info(
                    "ecs_api_response",
                    extra={
                        "event": "ecs_api_response",
                        "http_method": self.command,
                        "path": path,
                        "route": route,
                        "status_code": 200,
                        "request_id": request_id,
                        "service": SERVICE_NAME,
                    },
                )
                self._write_json(200, {"status": "ok", "service": SERVICE_NAME})
                return

            if route in ("/fail", "/error"):
                span.set_attribute("http.status_code", 500)
                logger.error(
                    "ecs_api_forced_failure",
                    extra={
                        "event": "ecs_api_forced_failure",
                        "http_method": self.command,
                        "path": path,
                        "route": route,
                        "status_code": 500,
                        "request_id": request_id,
                        "service": SERVICE_NAME,
                    },
                )
                self._write_json(
                    500,
                    {
                        "message": "Forced failure for testing",
                        "service": SERVICE_NAME,
                        "route": route,
                    },
                )
                return

            span.set_attribute("http.status_code", 200)
            logger.info(
                "ecs_api_response",
                extra={
                    "event": "ecs_api_response",
                    "http_method": self.command,
                    "path": path,
                    "route": route,
                    "status_code": 200,
                    "request_id": request_id,
                    "service": SERVICE_NAME,
                },
            )
            self._write_json(
                200,
                {
                    "message": "Hello from the blue/green ECS API",
                    "service": SERVICE_NAME,
                    "hostname": socket.gethostname(),
                    "image": IMAGE,
                    "root_path": ROOT_PATH_PREFIX,
                    "route": route,
                },
            )

    def log_message(self, format: str, *args) -> None:
        return


if __name__ == "__main__":
    httpd = HTTPServer((HOST, PORT), Handler)
    logger.info(
        "ecs_api_startup",
        extra={
            "event": "ecs_api_startup",
            "service": SERVICE_NAME,
            "host": HOST,
            "port": PORT,
            "root_path": ROOT_PATH_PREFIX or "/",
        },
    )
    httpd.serve_forever()
