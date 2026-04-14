import json
import os
import socket
from http.server import BaseHTTPRequestHandler, HTTPServer


HOST = "0.0.0.0"
PORT = int(os.getenv("PORT", "80"))
ROOT_PATH = os.getenv("ROOT_PATH", "")
SERVICE_NAME = os.getenv("AWS_SERVICE_NAME", "ecs-service-api")
IMAGE = os.getenv("IMAGE", "unknown")


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
        route = route_for(self.path.split("?", 1)[0])

        if route == "/health":
            self._write_json(200, {"status": "ok", "service": SERVICE_NAME})
            return

        if route in ("/fail", "/error"):
            self._write_json(
                500,
                {
                    "message": "Forced failure for testing",
                    "service": SERVICE_NAME,
                    "route": route,
                },
            )
            return

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


if __name__ == "__main__":
    httpd = HTTPServer((HOST, PORT), Handler)
    print(f"Starting {SERVICE_NAME} on {HOST}:{PORT} with root path {ROOT_PATH_PREFIX or '/'}")
    httpd.serve_forever()
