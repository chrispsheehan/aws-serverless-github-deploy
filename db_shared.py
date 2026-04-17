import json
import os
from functools import lru_cache
from urllib.parse import quote

import boto3
import psycopg
import time

from lambda_shared import get_logger


logger = get_logger(__name__)


def _required_env(name: str) -> str:
    value = os.getenv(name, "").strip()
    if not value:
        raise RuntimeError(f"Missing required environment variable: {name}")
    return value


@lru_cache(maxsize=1)
def _load_db_credentials() -> dict[str, str]:
    start = time.monotonic()
    region = _required_env("AWS_REGION")
    secret_arn = _required_env("DB_SECRET_ARN")
    secretsmanager = boto3.client("secretsmanager", region_name=region)
    response = secretsmanager.get_secret_value(SecretId=secret_arn)
    secret_string = response.get("SecretString", "")
    if not secret_string:
        raise RuntimeError(f"Secret {secret_arn} did not contain SecretString")

    values = json.loads(secret_string)
    if "username" not in values or "password" not in values:
        raise RuntimeError(f"Secret {secret_arn} must contain username and password keys")

    logger.info(
        "db_credentials_loaded",
        extra={
            "event": "db_credentials_loaded",
            "duration_ms": round((time.monotonic() - start) * 1000, 1),
            "region": region,
        },
    )

    return {
        "user": values["username"],
        "password": values["password"],
    }


def connect():
    start = time.monotonic()
    credentials = _load_db_credentials()
    connection = psycopg.connect(
        host=_required_env("DB_HOST"),
        dbname=_required_env("DB_NAME"),
        port=int(_required_env("DB_PORT")),
        user=credentials["user"],
        password=credentials["password"],
        connect_timeout=5,
    )
    logger.info(
        "db_connected",
        extra={
            "event": "db_connected",
            "duration_ms": round((time.monotonic() - start) * 1000, 1),
            "host": _required_env("DB_HOST"),
            "database": _required_env("DB_NAME"),
            "port": int(_required_env("DB_PORT")),
        },
    )
    return connection


def postgres_url() -> str:
    credentials = _load_db_credentials()
    return (
        f"postgres://{quote(credentials['user'])}:{quote(credentials['password'])}"
        f"@{_required_env('DB_HOST')}:{int(_required_env('DB_PORT'))}"
        f"/{quote(_required_env('DB_NAME'))}"
    )
