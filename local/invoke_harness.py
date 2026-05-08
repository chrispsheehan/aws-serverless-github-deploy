#!/usr/bin/env python3
from __future__ import annotations

import argparse
import importlib
import json
import os
from pathlib import Path
from typing import Callable


class LambdaInvokeContext:
    function_name = "local_invoke_handler"
    function_version = "$LATEST"

    def __init__(self, aws_request_id: str = "local-invoke-request") -> None:
        self.aws_request_id = aws_request_id


def import_handler(import_path: str) -> Callable[[dict, object], dict]:
    module_name, attr_name = import_path.split(":", 1)
    module = importlib.import_module(module_name)
    return getattr(module, attr_name)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Invoke a Lambda-style handler locally.")
    parser.add_argument("handler_import_path", help="Import path in module:attribute form.")
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--event-json", help="Inline JSON event payload.")
    group.add_argument("--event-file", help="Path to a JSON event file.")
    parser.add_argument(
        "--request-id",
        default=os.getenv("LOCAL_INVOKE_REQUEST_ID", "local-invoke-request"),
        help="Request id for the local context.",
    )
    parser.add_argument(
        "--function-name",
        default=os.getenv("LOCAL_INVOKE_FUNCTION_NAME", "local_invoke_handler"),
        help="Function name for the local context.",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    handler = import_handler(args.handler_import_path)
    if args.event_file:
        event = json.loads(Path(args.event_file).read_text(encoding="utf-8"))
    else:
        event = json.loads(args.event_json)
    context = LambdaInvokeContext(aws_request_id=args.request_id)
    context.function_name = args.function_name
    handler(event, context)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
