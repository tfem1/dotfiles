"""Checks the Hyprland config with Hyprland itself: `Hyprland --verify-config`
loads hypr/hyprland.lua (and the generated theme.lua and shell.lua) the way
the compositor does at login, and prints "config ok" or each error.

test_hypr.py runs the config in a fake Hyprland API (fast, everywhere); this
one catches what only the real one knows: unknown options, wrong values.
Skipped without Hyprland, or as root (Hyprland refuses to run as root).
"""
from __future__ import annotations

import contextlib
import io
import os
import shutil
import subprocess
import unittest

from helpers import REPO, SandboxTest
from theming.generate import main as generate

HYPRLAND = shutil.which("Hyprland")


@unittest.skipUnless(HYPRLAND, "Hyprland not installed")
@unittest.skipIf(hasattr(os, "geteuid") and os.geteuid() == 0, "Hyprland does not run as root")
class HyprlandVerifyTest(SandboxTest):
    def test_the_installed_config_is_ok(self):
        hypr = self.home / ".config/hypr"
        shutil.copytree(REPO / "hypr", hypr)
        # A mode picked in Settings → Display, a key changed in Settings → Keybinds.
        self.write_user_file("config.json", '{"display": {"modes": {"DP-1": "2560x1440@165.08"}}, '
                                            '"keys": {"pick": "SUPER + SHIFT + P"}}')
        # theme.lua and shell.lua as the installer generates them. An empty
        # PATH: the generator then never reloads the Hyprland you are using.
        empty = self.home / "empty-bin"
        empty.mkdir()
        with contextlib.redirect_stdout(io.StringIO()):
            code = generate(["--root", str(REPO), "--only", "hyprland,hyprland-shell,hyprland-display,hyprland-keys", "--all"],
                            env={**self.env, "PATH": str(empty)})
        self.assertEqual(code, 0)
        runtime = self.home / "run"
        runtime.mkdir(mode=0o700)
        env = {**self.env, "XDG_RUNTIME_DIR": str(runtime), "PATH": os.environ.get("PATH", "")}
        done = subprocess.run([HYPRLAND, "--verify-config", "-c", str(hypr / "hyprland.lua")],
                              env=env, capture_output=True, text=True, timeout=60)
        output = done.stdout + done.stderr
        result = output.split("Config parsing result:")[-1].strip()
        self.assertEqual(done.returncode, 0, result)
        self.assertEqual(result, "config ok")
        self.assertIn('output = "DP-1"', (hypr / "display.lua").read_text())
        self.assertIn('key = "SUPER + SHIFT + P", run = "~/.local/bin/tfem pick"', (hypr / "keys.lua").read_text())


if __name__ == "__main__":
    unittest.main()
