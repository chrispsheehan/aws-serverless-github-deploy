import json
import sys
from sqlalchemy import create_engine, inspect

from lambda_shared import get_logger, json_response
from db_shared import postgres_url
from database_models import Base, WorkerMessage

MIGRATION_NAME = "001_create_worker_messages"
logger = get_logger(__name__)
WORKER_MESSAGE_COLUMN_SQL = {
    "message_type": "alter table public.worker_messages add column message_type text",
    "correlation_id": "alter table public.worker_messages add column correlation_id text",
    "source_queue": "alter table public.worker_messages add column source_queue text",
    "processed_at": "alter table public.worker_messages add column processed_at timestamptz not null default now()",
}


def _sqlalchemy_url() -> str:
    url = postgres_url()
    if url.startswith("postgresql://"):
        return url.replace("postgresql://", "postgresql+psycopg://", 1)
    if url.startswith("postgres://"):
        return url.replace("postgres://", "postgresql+psycopg://", 1)
    return url


def _ensure_tables() -> dict[str, object]:
    engine = create_engine(_sqlalchemy_url(), pool_pre_ping=True)
    try:
        inspector = inspect(engine)
        worker_messages_exists = inspector.has_table(WorkerMessage.__tablename__, schema="public")
        logger.info(
            "migration_db_state",
            extra={
                "event": "migration_db_state",
                "worker_messages_exists": worker_messages_exists,
                "managed_tables": sorted(Base.metadata.tables.keys()),
            },
        )
        if worker_messages_exists:
            existing_columns = {
                column["name"] for column in inspector.get_columns(WorkerMessage.__tablename__, schema="public")
            }
            added_columns = []
            with engine.begin() as connection:
                for column_name, statement in WORKER_MESSAGE_COLUMN_SQL.items():
                    if column_name in existing_columns:
                        continue
                    connection.exec_driver_sql(statement)
                    added_columns.append(column_name)
            return {
                "created_any": False,
                "added_columns": added_columns,
                "managed_tables": sorted(Base.metadata.tables.keys()),
            }

        Base.metadata.create_all(bind=engine, tables=[WorkerMessage.__table__], checkfirst=True)
        return {
            "created_any": True,
            "added_columns": [],
            "managed_tables": sorted(Base.metadata.tables.keys()),
        }
    finally:
        engine.dispose()


def run_migration(request_id: str = "local") -> dict[str, object]:
    logger.info(
        "migration_start",
        extra={
            "event": "migration_start",
            "migration": MIGRATION_NAME,
            "managed_tables": sorted(Base.metadata.tables.keys()),
            "request_id": request_id,
        },
    )

    result = _ensure_tables()
    if not result["created_any"]:
        payload = {
            "ok": True,
            "migration": MIGRATION_NAME,
            "skipped": not result["added_columns"],
            "reason": "worker_messages already exists in public schema",
            "added_columns": result["added_columns"],
            "managed_tables": result["managed_tables"],
        }
        logger.info(
            "migration_complete",
            extra={
                "event": "migration_complete",
                "migration": MIGRATION_NAME,
                "request_id": request_id,
                "skipped": not result["added_columns"],
                "added_columns": result["added_columns"],
                "managed_tables": result["managed_tables"],
            },
        )
        return payload

    payload = {
        "ok": True,
        "migration": MIGRATION_NAME,
        "created_tables": result["managed_tables"],
    }
    logger.info(
        "migration_complete",
        extra={
            "event": "migration_complete",
            "migration": MIGRATION_NAME,
            "request_id": request_id,
            "skipped": False,
            "created_tables": result["managed_tables"],
        },
    )
    return payload


def lambda_handler(event, context):
    return json_response(200, run_migration(request_id=context.aws_request_id))


def main() -> int:
    payload = run_migration()
    print(json.dumps(payload, indent=2, default=str))
    return 0 if payload.get("ok") else 1


if __name__ == "__main__":
    sys.exit(main())
