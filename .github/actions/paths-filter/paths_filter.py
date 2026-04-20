#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
from typing import Iterable


CATEGORY_PREFIXES = {
    "terraform": ("infra/modules/",),
    "terragrunt": ("infra/",),
    "github": (".github/",),
    "lambdas": ("lambdas/",),
    "containers": ("containers/",),
    "frontend": ("frontend/",),
}


def run_git(*args: str, check: bool = True) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["git", *args],
        check=check,
        text=True,
        capture_output=True,
    )


def ref_exists(ref: str) -> bool:
    return run_git("rev-parse", "--verify", ref, check=False).returncode == 0


def resolve_diff_range(base_ref: str) -> tuple[str, str | None]:
    if ref_exists(base_ref):
        return f"{base_ref}..HEAD", None
    origin_ref = f"origin/{base_ref}"
    if ref_exists(origin_ref):
        return f"{origin_ref}..HEAD", None
    return "HEAD^..HEAD", f"Base ref '{base_ref}' not found locally, falling back to HEAD^..HEAD"


def changed_files(diff_range: str) -> list[str]:
    result = run_git("diff", "--name-only", diff_range, check=False)
    if result.returncode not in (0, 1):
        raise RuntimeError(result.stderr.strip() or f"git diff failed for {diff_range}")
    return [line for line in result.stdout.splitlines() if line]


def classify_paths(paths: Iterable[str]) -> dict[str, str]:
    path_list = list(paths)
    outputs: dict[str, str] = {}
    for category, prefixes in CATEGORY_PREFIXES.items():
        matched = any(path.startswith(prefixes) for path in path_list)
        outputs[category] = "true" if matched else "false"
    return outputs


def write_github_outputs(outputs: dict[str, str]) -> None:
    github_output = os.environ.get("GITHUB_OUTPUT")
    if not github_output:
        return
    with open(github_output, "a", encoding="utf-8") as handle:
        for key, value in outputs.items():
            handle.write(f"{key}={value}\n")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Detect changed-file categories for this repo")
    parser.add_argument("--ref", default="main", help="Git reference to compare from")
    parser.add_argument(
        "--format",
        choices=("json", "pretty"),
        default="json",
        help="CLI output format",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    diff_range, warning = resolve_diff_range(args.ref)
    paths = changed_files(diff_range)
    outputs = classify_paths(paths)
    write_github_outputs(outputs)

    payload = {
        "ref": args.ref,
        "diffRange": diff_range,
        "changedFiles": paths,
        "outputs": outputs,
    }

    if warning:
        print(f"warning: {warning}", file=sys.stderr)

    if args.format == "pretty":
        print(f"ref: {payload['ref']}")
        print(f"diff_range: {payload['diffRange']}")
        print("changed_files:")
        for path in payload["changedFiles"]:
            print(f"- {path}")
        print("outputs:")
        for key, value in payload["outputs"].items():
            print(f"- {key}: {value}")
    else:
        print(json.dumps(payload))

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
