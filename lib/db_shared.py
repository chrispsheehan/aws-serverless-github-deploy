from __future__ import annotations

import json
import os
from typing import Any

import boto3

from runtime_logging import get_logger

logger = get_logger(__name__)


def postgres_url(secret_json: dict[str, Any] | None = None) -> str:
    if secret_json is None:
        database_url = os.getenv("DATABASE_URL")
        if database_url:
            return database_url

        secret_arn = os.getenv("DB_SECRET_ARN")
        host = os.getenv("DB_HOST")
        port = os.getenv("DB_PORT")
        dbname = os.getenv("DB_NAME")

        if not all([secret_arn, host, port, dbname]):
            raise RuntimeError(
                "postgres_url() requires DATABASE_URL or the DB_SECRET_ARN/DB_HOST/DB_PORT/DB_NAME environment variables"
            )

        secret_json = _load_secret(secret_arn)
        secret_json = {
            **secret_json,
            "host": host,
            "port": port,
            "dbname": dbname,
        }

    host = secret_json["host"]
    port = secret_json["port"]
    dbname = secret_json["dbname"]
    username = secret_json["username"]
    password = secret_json["password"]

    return f"postgresql://{username}:{password}@{host}:{port}/{dbname}"


def connect():
    import psycopg

    database_url = postgres_url()
    logger.info("Connecting to database", extra={"host": database_url.split('@')[-1]})
    return psycopg.connect(database_url)


def _load_secret(secret_arn: str) -> dict[str, Any]:
    aws_region = os.getenv("AWS_REGION")
    client = boto3.client("secretsmanager", region_name=aws_region) if aws_region else boto3.client("secretsmanager")
    response = client.get_secret_value(SecretId=secret_arn)
    secret_string = response.get("SecretString")
    if not secret_string:
        raise RuntimeError(f"Secret {secret_arn} did not contain SecretString")
    return json.loads(secret_string)
