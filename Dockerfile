ARG SERVICE

FROM python:3.12-slim AS python-base

WORKDIR /usr/app

FROM python-base AS service-base

ARG SERVICE

COPY containers/shared/requirements.txt /tmp/shared-requirements.txt
COPY containers/${SERVICE}/requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir -r /tmp/shared-requirements.txt -r /tmp/requirements.txt


FROM service-base AS worker

ARG SERVICE

COPY containers/shared/ecs_tracing.py /usr/app/ecs_tracing.py
COPY containers/${SERVICE}/app.py /usr/app/app.py

CMD ["python", "-u", "app.py"]


FROM service-base AS api

ARG SERVICE

COPY containers/shared/ecs_tracing.py /usr/app/ecs_tracing.py
COPY containers/${SERVICE}/app.py /usr/app/app.py

CMD ["python", "-u", "app.py"]


FROM python-base AS debug

RUN apt-get update \
    && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/*

CMD ["sleep", "infinity"]


FROM public.ecr.aws/aws-observability/aws-otel-collector:latest AS collector

COPY config/otel/collector-config.yaml /opt/aws/aws-otel-collector/etc/collector-config.yaml

CMD ["--config", "/opt/aws/aws-otel-collector/etc/collector-config.yaml"]


FROM collector AS otel_collector
