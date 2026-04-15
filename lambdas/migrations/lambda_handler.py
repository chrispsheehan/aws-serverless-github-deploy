import os
import subprocess
from pathlib import Path

from db_shared import connect, postgres_url
from lambda_shared import json_response

PGROLL_BINARY = Path(os.getenv("LAMBDA_TASK_ROOT", "/var/task")) / "bin" / "pgroll"
MIGRATION_FILE = Path(os.getenv("LAMBDA_TASK_ROOT", "/var/task")) / "migrations" / "001_create_worker_messages.json"


def _run_pgroll(*args: str) -> dict[str, object]:
    command = [str(PGROLL_BINARY), "--postgres-url", postgres_url(), *args]
    print({"event": "pgroll_command_start", "command": command})
    result = subprocess.run(
        command,
        check=False,
        capture_output=True,
        text=True,
        timeout=300,
    )
    payload = {
        "event": "pgroll_command_complete",
        "command": command,
        "returncode": result.returncode,
        "stdout": result.stdout.strip(),
        "stderr": result.stderr.strip(),
    }
    print(payload)
    if result.returncode != 0:
        raise RuntimeError(f"pgroll command failed: {payload}")
    return payload


def _database_state() -> dict[str, object]:
    with connect() as connection:
        with connection.cursor() as cursor:
            cursor.execute(
                """
                select
                    to_regclass('public.worker_messages') is not null,
                    to_regclass('pgroll.migrations') is not null,
                    (
                        select count(*)
                        from information_schema.tables
                        where table_schema = 'public'
                    )
                """
            )
            worker_messages_exists, pgroll_initialized, public_table_count = cursor.fetchone()
    state = {
        "worker_messages_exists": worker_messages_exists,
        "pgroll_initialized": pgroll_initialized,
        "public_table_count": public_table_count,
    }
    print({"event": "migration_db_state", **state})
    return state


def lambda_handler(event, context):
    print(
        {
            "event": "migration_start",
            "migration": "001_create_worker_messages",
            "pgroll_binary": str(PGROLL_BINARY),
            "migration_file": str(MIGRATION_FILE),
        }
    )
    state = _database_state()
    if state["worker_messages_exists"]:
        return json_response(
            200,
            {
                "ok": True,
                "migration": "001_create_worker_messages",
                "skipped": True,
                "reason": "worker_messages already exists in public schema",
            },
        )

    if not state["pgroll_initialized"]:
        _run_pgroll("init")
        if state["public_table_count"] > 0:
            _run_pgroll("baseline", "--yes")

    _run_pgroll("start", str(MIGRATION_FILE))
    _run_pgroll("complete")

    return json_response(
        200,
        {
            "ok": True,
            "migration": "001_create_worker_messages",
        },
    )
