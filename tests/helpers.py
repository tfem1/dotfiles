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
            # The login screen's folder (/var/lib/tfem/sddm), not created here.
            "TFEM_SDDM_DIR": str(self.home / "var/lib/tfem/sddm"),
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


def fake_fairywren(folder: Path) -> str:
    """A tiny git repository shaped like FairyWren-Icons (each theme's folder
    icons link to places/colours/default, itself a link to ./blue). Returns
    a URL for TFEM_FAIRYWREN_URL, so no test downloads the real one."""
    import subprocess
    for theme in ("FairyWren_Dark", "FairyWren_Light"):
        places = folder / theme / "places"
        for color in ("blue", "pink", "violet"):
            (places / "colours" / color).mkdir(parents=True)
            (places / "colours" / color / "folder.svg").write_text(f"<svg><!-- {color} --></svg>\n")
        (places / "colours/default").symlink_to("./blue")
        (places / "folder.svg").symlink_to("./colours/default/folder.svg")
        (folder / theme / "index.theme").write_text(f"[Icon Theme]\nName={theme}\nDirectories=places\n")
    (folder / "README.md").write_text("not copied\n")
    git = ["git", "-C", str(folder), "-c", "user.name=test", "-c", "user.email=test@example.org"]
    for step in (["init", "--quiet"], ["add", "-A"], ["commit", "--quiet", "-m", "fake"]):
        subprocess.run(git + step, check=True, capture_output=True)
    return folder.as_uri()
