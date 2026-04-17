from sqlalchemy import create_engine, inspect

from lambda_shared import json_response
from db_shared import postgres_url
from database_models import Base, WorkerMessage

MIGRATION_NAME = "001_create_worker_messages"


def _sqlalchemy_url() -> str:
    return postgres_url().replace("postgres://", "postgresql+psycopg://", 1)


def _ensure_tables() -> dict[str, object]:
    engine = create_engine(_sqlalchemy_url(), pool_pre_ping=True)
    try:
        inspector = inspect(engine)
        worker_messages_exists = inspector.has_table(WorkerMessage.__tablename__, schema="public")
        print(
            {
                "event": "migration_db_state",
                "worker_messages_exists": worker_messages_exists,
                "managed_tables": sorted(Base.metadata.tables.keys()),
            }
        )
        if worker_messages_exists:
            return {
                "created_any": False,
                "managed_tables": sorted(Base.metadata.tables.keys()),
            }

        Base.metadata.create_all(bind=engine, tables=[WorkerMessage.__table__], checkfirst=True)
        return {
            "created_any": True,
            "managed_tables": sorted(Base.metadata.tables.keys()),
        }
    finally:
        engine.dispose()


def lambda_handler(event, context):
    print(
        {
            "event": "migration_start",
            "migration": MIGRATION_NAME,
            "managed_tables": sorted(Base.metadata.tables.keys()),
        }
    )
    result = _ensure_tables()
    if not result["created_any"]:
        return json_response(
            200,
            {
                "ok": True,
                "migration": MIGRATION_NAME,
                "skipped": True,
                "reason": "worker_messages already exists in public schema",
                "managed_tables": result["managed_tables"],
            },
        )

    return json_response(
        200,
        {
            "ok": True,
            "migration": MIGRATION_NAME,
            "created_tables": result["managed_tables"],
        },
    )
