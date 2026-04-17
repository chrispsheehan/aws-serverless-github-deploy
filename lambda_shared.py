import json
from runtime_logging import get_logger, setup_logging


def json_response(status_code: int, body: dict, headers: dict | None = None) -> dict:
    response_headers = {
        "Content-Type": "application/json",
    }
    if headers:
        response_headers.update(headers)

    return {
        "statusCode": status_code,
        "headers": response_headers,
        "body": json.dumps(body),
    }
