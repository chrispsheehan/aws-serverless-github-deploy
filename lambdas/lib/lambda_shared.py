from runtime_logging import get_logger, setup_logging


def json_response(body, status_code=200):
    return {
        "statusCode": status_code,
        "headers": {"Content-Type": "application/json"},
        "body": body,
    }
