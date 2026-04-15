from db_shared import connect
from lambda_shared import json_response


def lambda_handler(event, context):
    with connect() as connection:
        with connection.cursor() as cursor:
            cursor.execute(
                """
                create table if not exists worker_messages (
                    id bigserial primary key,
                    sqs_message_id text not null unique,
                    job_id text,
                    message_body text not null,
                    created_at timestamptz not null default now()
                )
                """
            )

    return json_response(
        200,
        {
            "ok": True,
            "migration": "create_worker_messages_table",
        },
    )
