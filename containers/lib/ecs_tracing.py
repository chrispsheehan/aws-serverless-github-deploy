from __future__ import annotations

from contextlib import contextmanager

from opentelemetry import trace
from opentelemetry.propagate import extract


def extract_context(carrier: dict[str, str] | None):
    return extract(carrier or {})


@contextmanager
def start_span(name: str, context=None, attributes: dict | None = None):
    tracer = trace.get_tracer(__name__)
    with tracer.start_as_current_span(name, context=context) as span:
        for key, value in (attributes or {}).items():
            span.set_attribute(key, value)
        yield span
