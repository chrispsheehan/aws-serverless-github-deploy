#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json

from get_next_version import classify_bump, parse_prefixes


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Preflight the commit-prefix versioning rules against common direct-push and PR-merge cases."
    )
    parser.add_argument(
        "--major-prefixes",
        default="breaking,major",
        help="Comma-separated commit prefixes that trigger a major bump.",
    )
    parser.add_argument(
        "--minor-prefixes",
        default="feat,minor",
        help="Comma-separated commit prefixes that trigger a minor bump.",
    )
    parser.add_argument(
        "--patch-prefixes",
        default="fix,chore",
        help="Comma-separated commit prefixes that trigger a patch bump.",
    )
    parser.add_argument(
        "--direct-subject",
        default="chore: things",
        help="Example direct-push commit subject to validate.",
    )
    parser.add_argument(
        "--pr-subject",
        default="fix: this and that",
        help="Example PR subject or squash/rebase commit subject to validate.",
    )
    parser.add_argument(
        "--merge-commit-subject",
        default="Merge pull request #123 from example/branch",
        help="Example default merge-commit subject to validate.",
    )
    return parser.parse_args()


def bump_for(subject: str, *, major: list[str], minor: list[str], patch: list[str]) -> str:
    return classify_bump([subject], major=major, minor=minor, patch=patch) or ""


def main() -> int:
    args = parse_args()
    major = parse_prefixes(args.major_prefixes)
    minor = parse_prefixes(args.minor_prefixes)
    patch = parse_prefixes(args.patch_prefixes)

    checks = [
        {
            "name": "direct_push_main",
            "subject": args.direct_subject,
            "expected_feasible": True,
            "actual_bump": bump_for(args.direct_subject, major=major, minor=minor, patch=patch),
        },
        {
            "name": "pr_merge_squash_or_rebase",
            "subject": args.pr_subject,
            "expected_feasible": True,
            "actual_bump": bump_for(args.pr_subject, major=major, minor=minor, patch=patch),
        },
        {
            "name": "pr_merge_default_merge_commit",
            "subject": args.merge_commit_subject,
            "expected_feasible": False,
            "actual_bump": bump_for(args.merge_commit_subject, major=major, minor=minor, patch=patch),
        },
    ]

    for check in checks:
        check["actual_feasible"] = bool(check["actual_bump"])
        check["passes"] = check["actual_feasible"] == check["expected_feasible"]

    payload = {
        "major_prefixes": major,
        "minor_prefixes": minor,
        "patch_prefixes": patch,
        "checks": checks,
        "all_passed": all(check["passes"] for check in checks),
    }

    print(json.dumps(payload))
    return 0 if payload["all_passed"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
