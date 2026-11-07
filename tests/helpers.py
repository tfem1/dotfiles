"""Shared test helpers: an isolated fake $HOME around a copy of the repository."""
from __future__ import annotations

import os
import shutil
import tempfile
import unittest
from pathlib import Path

from theming.paths import Paths

REPO = Path(__file__).resolve().parent.parent


class SandboxTest(unittest.TestCase):
    """Each test gets an empty HOME and XDG paths pointing inside it."""

    def setUp(self):
        self._tmp = tempfile.TemporaryDirectory()
        self.home = Path(self._tmp.name)
        self.env = {
            "HOME": str(self.home),
            "XDG_CONFIG_HOME": str(self.home / ".config"),
            "XDG_STATE_HOME": str(self.home / ".local/state"),
        }
        self.paths = Paths.from_env(REPO, self.env)

    def tearDown(self):
        self._tmp.cleanup()

    def write_user_file(self, name: str, text: str) -> Path:
        path = self.paths.user_dir / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text)
        return path

    def copy_repo(self) -> Paths:
        """Copy the repository into the sandbox, for tests that change its files."""
        root = self.home / "repo"
        shutil.copytree(REPO, root, ignore=shutil.ignore_patterns(".git", "__pycache__"))
        self.paths = Paths.from_env(root, self.env)
        return self.paths


def environ_with(env: dict[str, str]) -> dict[str, str]:
    return {**os.environ, **env}
