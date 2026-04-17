"""Worker message persistence model."""

from datetime import datetime

from sqlalchemy import DateTime, Text, func
from sqlalchemy.dialects.postgresql import BIGINT
from sqlalchemy.orm import Mapped, mapped_column

from database_models.base import Base


class WorkerMessage(Base):
    """Messages persisted by the worker runtime."""

    __tablename__ = "worker_messages"

    id: Mapped[int] = mapped_column(BIGINT, primary_key=True, autoincrement=True)
    sqs_message_id: Mapped[str | None] = mapped_column(Text, unique=True)
    job_id: Mapped[str | None] = mapped_column(Text, nullable=True)
    message_body: Mapped[str] = mapped_column(Text, nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
    )
