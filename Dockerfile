FROM python:3.12-slim AS python-base

WORKDIR /usr/app

COPY containers/worker/requirements.txt /tmp/requirements-worker.txt
RUN pip install --no-cache-dir -r /tmp/requirements-worker.txt


FROM python-base AS worker

COPY containers/worker/app.py /usr/app/app.py

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
