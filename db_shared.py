import os
from functools import lru_cache

import boto3
import psycopg


def _required_env(name: str) -> str:
    value = os.getenv(name, "").strip()
    if not value:
        raise RuntimeError(f"Missing required environment variable: {name}")
    return value


@lru_cache(maxsize=1)
def _load_db_credentials() -> dict[str, str]:
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

    return {
        "user": values[username_parameter],
        "password": values[password_parameter],
    }


def connect():
    credentials = _load_db_credentials()
    return psycopg.connect(
        host=_required_env("DB_HOST"),
        dbname=_required_env("DB_NAME"),
        port=int(_required_env("DB_PORT")),
        user=credentials["user"],
        password=credentials["password"],
        connect_timeout=5,
    )
