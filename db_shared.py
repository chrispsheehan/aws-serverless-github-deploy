import os
from functools import lru_cache
from urllib.parse import quote

import boto3
import psycopg
import time


def _required_env(name: str) -> str:
    value = os.getenv(name, "").strip()
    if not value:
        raise RuntimeError(f"Missing required environment variable: {name}")
    return value


@lru_cache(maxsize=1)
def _load_db_credentials() -> dict[str, str]:
    start = time.monotonic()
    region = _required_env("AWS_REGION")
    username_parameter = _required_env("DB_USERNAME_SSM_PARAMETER")
    password_parameter = _required_env("DB_PASSWORD_SSM_PARAMETER")

    ssm = boto3.client("ssm", region_name=region)
    response = ssm.get_parameters(
        Names=[username_parameter, password_parameter],
        WithDecryption=True,
    )

    invalid_parameters = response.get("InvalidParameters", [])
    if invalid_parameters:
        raise RuntimeError(
            f"Could not load SSM parameters: {', '.join(sorted(invalid_parameters))}"
        )

    values = {
        parameter["Name"]: parameter["Value"]
        for parameter in response.get("Parameters", [])
    }

    print(
        {
            "event": "db_credentials_loaded",
            "duration_ms": round((time.monotonic() - start) * 1000, 1),
            "region": region,
        }
    )

    return {
        "user": values[username_parameter],
        "password": values[password_parameter],
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
    print(
        {
            "event": "db_connected",
            "duration_ms": round((time.monotonic() - start) * 1000, 1),
            "host": _required_env("DB_HOST"),
            "database": _required_env("DB_NAME"),
            "port": int(_required_env("DB_PORT")),
        }
    )
    return connection


def postgres_url() -> str:
    credentials = _load_db_credentials()
    return (
        f"postgres://{quote(credentials['user'])}:{quote(credentials['password'])}"
        f"@{_required_env('DB_HOST')}:{int(_required_env('DB_PORT'))}"
        f"/{quote(_required_env('DB_NAME'))}"
    )
