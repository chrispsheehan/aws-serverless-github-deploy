#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
import os
import subprocess
import tempfile
import unittest
from pathlib import Path

from get_next_version import classify_bump, parse_prefixes, resolve_workspace


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Preflight the commit-prefix versioning rules against common direct-push and PR-merge cases."
    )
    parser.add_argument(
        "--major-prefixes",
        default="breaking,feat,!feat",
        help="Comma-separated commit prefixes that trigger a major bump.",
    )
    parser.add_argument(
        "--minor-prefixes",
        default="minor,fix,patch",
        help="Comma-separated commit prefixes that trigger a minor bump.",
    )
    parser.add_argument(
        "--patch-prefixes",
        default="chore,docs",
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


def bump_for_subjects(subjects: list[str], *, major: list[str], minor: list[str], patch: list[str]) -> str:
    return classify_bump(subjects, major=major, minor=minor, patch=patch) or ""


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
            "expected_bump": "patch",
            "actual_bump": bump_for(args.direct_subject, major=major, minor=minor, patch=patch),
        },
        {
            "name": "pr_merge_squash_or_rebase",
            "subject": args.pr_subject,
            "expected_feasible": True,
            "expected_bump": "minor",
            "actual_bump": bump_for(args.pr_subject, major=major, minor=minor, patch=patch),
        },
        {
            "name": "pr_merge_default_merge_commit",
            "subject": args.merge_commit_subject,
            "expected_feasible": False,
            "actual_bump": bump_for(args.merge_commit_subject, major=major, minor=minor, patch=patch),
        },
        {
            "name": "minor_direct_push",
            "subject": "feat: add reports endpoint",
            "expected_feasible": True,
            "expected_bump": "major",
            "actual_bump": bump_for("feat: add reports endpoint", major=major, minor=minor, patch=patch),
        },
        {
            "name": "major_direct_push",
            "subject": "major: remove legacy api",
            "expected_feasible": False,
            "actual_bump": bump_for("major: remove legacy api", major=major, minor=minor, patch=patch),
        },
        {
            "name": "breaking_bang_minor_prefix",
            "subject": "feat!: remove legacy auth flow",
            "expected_feasible": True,
            "expected_bump": "major",
            "actual_bump": bump_for("feat!: remove legacy auth flow", major=major, minor=minor, patch=patch),
        },
        {
            "name": "breaking_bang_patch_prefix",
            "subject": "fix!: remove deprecated response field",
            "expected_feasible": True,
            "expected_bump": "major",
            "actual_bump": bump_for("fix!: remove deprecated response field", major=major, minor=minor, patch=patch),
        },
        {
            "name": "unmatched_subject",
            "subject": "docs: update readme",
            "expected_feasible": True,
            "expected_bump": "patch",
            "actual_bump": bump_for("docs: update readme", major=major, minor=minor, patch=patch),
        },
        {
            "name": "case_insensitive_prefix",
            "subject": "Fix: preserve compatibility",
            "expected_feasible": True,
            "expected_bump": "minor",
            "actual_bump": bump_for("Fix: preserve compatibility", major=major, minor=minor, patch=patch),
        },
        {
            "name": "multi_commit_highest_bump_wins",
            "subjects": ["chore: tidy", "feat: add billing", "fix: patch worker"],
            "expected_feasible": True,
            "expected_bump": "major",
            "actual_bump": bump_for_subjects(
                ["chore: tidy", "feat: add billing", "fix: patch worker"],
                major=major,
                minor=minor,
                patch=patch,
            ),
        },
        {
            "name": "multi_commit_major_overrides_minor_patch",
            "subjects": ["fix: patch worker", "feat: add billing", "major: remove legacy api"],
            "expected_feasible": True,
            "expected_bump": "major",
            "actual_bump": bump_for_subjects(
                ["fix: patch worker", "feat: add billing", "major: remove legacy api"],
                major=major,
                minor=minor,
                patch=patch,
            ),
        },
    ]

    for check in checks:
        check["actual_feasible"] = bool(check["actual_bump"])
        expected_bump = check.get("expected_bump")
        bump_matches = expected_bump is None or check["actual_bump"] == expected_bump
        check["passes"] = check["actual_feasible"] == check["expected_feasible"] and bump_matches

    payload = {
        "major_prefixes": major,
        "minor_prefixes": minor,
        "patch_prefixes": patch,
        "checks": checks,
        "all_passed": all(check["passes"] for check in checks),
    }

    print(json.dumps(payload))
    return 0 if payload["all_passed"] else 1


class WorkspaceResolutionTests(unittest.TestCase):
    def test_resolve_workspace_walks_up_to_git_root(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            repo = Path(tmp) / "repo"
            nested = repo / ".github" / "actions" / "get-next-version"
            nested.mkdir(parents=True)
            (repo / ".git").mkdir()

            old_cwd = Path.cwd()
            try:
                os.chdir(nested)
                self.assertEqual(resolve_workspace().resolve(), repo.resolve())
            finally:
                os.chdir(old_cwd)

    def test_resolve_workspace_prefers_github_workspace(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            repo = Path(tmp) / "repo"
            repo.mkdir()
            old_value = os.environ.get("GITHUB_WORKSPACE")
            try:
                os.environ["GITHUB_WORKSPACE"] = str(repo)
                self.assertEqual(resolve_workspace().resolve(), repo.resolve())
            finally:
                if old_value is None:
                    os.environ.pop("GITHUB_WORKSPACE", None)
                else:
                    os.environ["GITHUB_WORKSPACE"] = old_value


if __name__ == "__main__":
    if "--run-unittest" in os.sys.argv:
        os.sys.argv.remove("--run-unittest")
        unittest.main()
    else:
        raise SystemExit(main())
