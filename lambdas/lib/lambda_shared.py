from runtime_logging import get_logger, setup_logging


def json_response(body, status_code=200):
    if isinstance(body, int) and isinstance(status_code, dict):
        body, status_code = status_code, body
    return {
        "statusCode": status_code,
        "headers": {"Content-Type": "application/json"},
        "body": body,
    }
