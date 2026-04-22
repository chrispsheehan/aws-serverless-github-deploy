from __future__ import annotations

from contextlib import contextmanager

from opentelemetry import trace
from opentelemetry.propagate import extract
from opentelemetry.propagators.textmap import Getter


class CarrierGetter(Getter):
    def get(self, carrier, key):
        if carrier is None:
            return []
        if callable(carrier):
            value = carrier(key)
        else:
            value = carrier.get(key)
        if value is None:
            return []
        return [value]

    def keys(self, carrier):
        if carrier is None or callable(carrier):
            return []
        return list(carrier.keys())


def extract_context(carrier=None):
    return extract(carrier=carrier or {}, getter=CarrierGetter())


@contextmanager
def start_span(name: str, context=None, kind=None, attributes: dict | None = None):
    tracer = trace.get_tracer(__name__)
    with tracer.start_as_current_span(name, context=context, kind=kind) as span:
        for key, value in (attributes or {}).items():
            span.set_attribute(key, value)
        yield span
