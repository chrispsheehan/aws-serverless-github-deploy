FROM public.ecr.aws/aws-observability/aws-otel-collector:latest AS collector

COPY ./collector-config.yaml /opt/aws/aws-otel-collector/etc/collector-config.yaml

CMD ["--config", "/opt/aws/aws-otel-collector/etc/collector-config.yaml"]