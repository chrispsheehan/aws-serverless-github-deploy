from __future__ import annotations

import os
from typing import Any

from runtime_logging import get_logger

logger = get_logger(__name__)


def postgres_url(secret_json: dict[str, Any]) -> str:
    host = secret_json["host"]
    port = secret_json["port"]
    dbname = secret_json["dbname"]
    username = secret_json["username"]
    password = secret_json["password"]

    return f"postgresql://{username}:{password}@{host}:{port}/{dbname}"


def connect():
    import psycopg

    database_url = os.environ["DATABASE_URL"]
    logger.info("Connecting to database", extra={"host": database_url.split('@')[-1]})
    return psycopg.connect(database_url)
