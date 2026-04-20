#!/usr/bin/env python3

from __future__ import annotations

import json
import os
import subprocess
import tempfile
import unittest
from pathlib import Path

from paths_filter import classify_paths, resolve_diff_range

ACTION_DIR = Path(__file__).resolve().parent


def git(repo: Path, *args: str) -> subprocess.CompletedProcess[str]:
    env = os.environ.copy()
    env.update(
        {
            "GIT_AUTHOR_NAME": "Test User",
            "GIT_AUTHOR_EMAIL": "test@example.com",
            "GIT_COMMITTER_NAME": "Test User",
            "GIT_COMMITTER_EMAIL": "test@example.com",
        }
    )
    command = ["git", *args]
    if args and args[0] == "commit":
        command = ["git", "-c", "commit.gpgsign=false", *args]
    return subprocess.run(
        command,
        cwd=repo,
        check=True,
        text=True,
        capture_output=True,
        env=env,
    )


class PathsFilterTests(unittest.TestCase):
    def test_classify_paths_maps_repo_prefixes(self) -> None:
        outputs = classify_paths(
            [
                "infra/modules/aws/example/main.tf",
                "infra/live/dev/aws/example/terragrunt.hcl",
                ".github/workflows/release.yml",
                "lambdas/lambda_api/lambda_handler.py",
                "containers/worker/app.py",
                "frontend/src/App.jsx",
            ]
        )

        self.assertEqual(
            outputs,
            {
                "terraform": "true",
                "terragrunt": "true",
                "github": "true",
                "lambdas": "true",
                "containers": "true",
                "frontend": "true",
            },
        )

    def test_classify_paths_handles_non_matches(self) -> None:
        outputs = classify_paths(["README.md", "docs/notes.md"])
        self.assertTrue(all(value == "false" for value in outputs.values()))

    def test_resolve_diff_range_prefers_local_ref(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            repo = Path(tmp)
            git(repo, "init", "-b", "main")
            git(repo, "config", "user.name", "Test User")
            git(repo, "config", "user.email", "test@example.com")
            (repo / "README.md").write_text("hello\n", encoding="utf-8")
            git(repo, "add", "README.md")
            git(repo, "commit", "-m", "chore: init")
            git(repo, "checkout", "-b", "feature")

            old_cwd = Path.cwd()
            try:
                import os

                os.chdir(repo)
                diff_range, warning = resolve_diff_range("main")
            finally:
                os.chdir(old_cwd)

            self.assertEqual(diff_range, "main..HEAD")
            self.assertIsNone(warning)


class PathsFilterCliTests(unittest.TestCase):
    def test_cli_reports_changed_categories(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            repo = Path(tmp)
            git(repo, "init", "-b", "main")
            git(repo, "config", "user.name", "Test User")
            git(repo, "config", "user.email", "test@example.com")

            (repo / "README.md").write_text("hello\n", encoding="utf-8")
            git(repo, "add", "README.md")
            git(repo, "commit", "-m", "chore: init")
            git(repo, "checkout", "-b", "feature")

            infra_dir = repo / "infra" / "modules" / "aws" / "example"
            infra_dir.mkdir(parents=True)
            (infra_dir / "main.tf").write_text("resource {}\n", encoding="utf-8")

            workflow_dir = repo / ".github" / "workflows"
            workflow_dir.mkdir(parents=True)
            (workflow_dir / "test.yml").write_text("name: test\n", encoding="utf-8")

            frontend_dir = repo / "frontend" / "src"
            frontend_dir.mkdir(parents=True)
            (frontend_dir / "App.jsx").write_text("export default null\n", encoding="utf-8")

            git(repo, "add", ".")
            git(repo, "commit", "-m", "feat: change repo")

            result = subprocess.run(
                ["python3", str(ACTION_DIR / "paths_filter.py"), "--ref", "main"],
                cwd=repo,
                check=True,
                text=True,
                capture_output=True,
            )
            payload = json.loads(result.stdout)

            self.assertEqual(Path(payload["workspace"]).resolve(), repo.resolve())
            self.assertEqual(payload["diffRange"], "main..HEAD")
            self.assertEqual(payload["outputs"]["terraform"], "true")
            self.assertEqual(payload["outputs"]["terragrunt"], "true")
            self.assertEqual(payload["outputs"]["github"], "true")
            self.assertEqual(payload["outputs"]["frontend"], "true")
            self.assertEqual(payload["outputs"]["lambdas"], "false")
            self.assertEqual(payload["outputs"]["containers"], "false")

    def test_cli_honors_github_workspace(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            repo = Path(tmp) / "repo"
            repo.mkdir()
            git(repo, "init", "-b", "main")
            git(repo, "config", "user.name", "Test User")
            git(repo, "config", "user.email", "test@example.com")

            (repo / ".github").mkdir(parents=True)
            (repo / ".github" / "test.txt").write_text("x\n", encoding="utf-8")
            git(repo, "add", ".")
            git(repo, "commit", "-m", "chore: init")
            git(repo, "checkout", "-b", "feature")

            (repo / "frontend").mkdir()
            (repo / "frontend" / "x.txt").write_text("x\n", encoding="utf-8")
            git(repo, "add", ".")
            git(repo, "commit", "-m", "feat: update frontend")

            result = subprocess.run(
                ["python3", str(ACTION_DIR / "paths_filter.py"), "--ref", "main"],
                cwd=repo.parent,
                check=True,
                text=True,
                capture_output=True,
                env=os.environ | {"GITHUB_WORKSPACE": str(repo)},
            )
            payload = json.loads(result.stdout)

            self.assertEqual(Path(payload["workspace"]).resolve(), repo.resolve())
            self.assertEqual(payload["outputs"]["frontend"], "true")


if __name__ == "__main__":
    unittest.main()
