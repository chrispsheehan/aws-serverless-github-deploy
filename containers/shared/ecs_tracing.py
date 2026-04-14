import os
from contextlib import contextmanager
from typing import Callable, Mapping

from opentelemetry import propagate, trace
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.sdk.extension.aws.trace import AwsXRayIdGenerator
from opentelemetry.sdk.resources import Resource
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.trace import SpanKind, Status, StatusCode


_CONFIGURED = False
_PROPAGATOR = propagate.get_global_textmap()


def tracing_enabled() -> bool:
    return os.getenv("XRAY_ENABLED", "false").lower() == "true"


def configure_tracing() -> None:
    global _CONFIGURED
    if _CONFIGURED or not tracing_enabled():
        return

    service_name = os.getenv("AWS_SERVICE_NAME", "ecs-service")
    endpoint = os.getenv("AWS_XRAY_ENDPOINT", "http://localhost:4317")

    trace.set_tracer_provider(
        TracerProvider(
            resource=Resource.create({"service.name": service_name}),
            id_generator=AwsXRayIdGenerator(),
        )
    )

    exporter = OTLPSpanExporter(endpoint=endpoint, insecure=True)
    trace.get_tracer_provider().add_span_processor(BatchSpanProcessor(exporter))
    _CONFIGURED = True


def get_tracer(name: str):
    configure_tracing()
    return trace.get_tracer(name)


def inject_headers(headers: dict[str, str]) -> None:
    _PROPAGATOR.inject(headers)


def extract_context(getter: Callable[[str], str | None]):
    carrier = {}
    for key in ("traceparent", "tracestate", "x-amzn-trace-id"):
        value = getter(key)
        if value:
            carrier[key] = value
    return _PROPAGATOR.extract(carrier=carrier)


@contextmanager
def start_span(name: str, kind: SpanKind, attributes: Mapping[str, object] | None = None, context=None):
    tracer = get_tracer(__name__)
    with tracer.start_as_current_span(name, kind=kind, context=context, attributes=attributes or {}) as span:
        try:
            yield span
        except Exception as exc:
            span.record_exception(exc)
            span.set_status(Status(StatusCode.ERROR))
            raise
