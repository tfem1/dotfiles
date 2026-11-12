"""Sway and Niri: their configs (keys, shell IPC calls; Sway's checked by
`sway -C`) and the generated theme files they include."""
import os
import re
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

from helpers import REPO
from test_hypr import ipc_handlers
from theming.keys import niri as niri_keys, resolve as resolve_keys, sway as sway_keys

# The shortcuts of Settings → Keybinds, as `tfem generate` writes them by default.
SWAY_KEYS = sway_keys(resolve_keys({}), "desktop")
NIRI_KEYS = niri_keys(resolve_keys({}), "desktop")

SWAY = shutil.which("sway")
# The keys every window manager config binds (same layout as Hyprland's).
KEYS = ["Return", "d", "q", "1", "0", "b", "m", "w", "s", "n", "v", "c", "h", "g", "a", "r", "l", "Escape", "Print"]


def ipc_calls(text):
    """(target, function) of every `qs ipc -c desktop call TARGET FUNCTION` (or $ipc TARGET FUNCTION)."""
    lines = [line for line in text.splitlines() if not line.startswith("set ")]
    return set(re.findall(r"(?:qs ipc -c desktop call|\$ipc) (\w+) (\w+)", "\n".join(lines)))


class SwayTest(unittest.TestCase):
    text = (REPO / "sway/config").read_text() + "\n" + SWAY_KEYS

    def test_every_ipc_call_reaches_a_handler(self):
        handlers = ipc_handlers()
        for target, function in ipc_calls(self.text):
            with self.subTest(call=f"{target} {function}"):
                self.assertIn(function, handlers.get(target, set()))
        self.assertGreaterEqual(len(ipc_calls(self.text)), 14)

    def test_the_usual_keys_are_bound(self):
        bound = {line.split()[1].split("+")[-1] for line in self.text.splitlines()
                 if line.startswith("bindsym") and not line.startswith("bindsym --")}
        bound |= {line.split()[2].split("+")[-1] for line in self.text.splitlines() if line.startswith("bindsym --")}
        self.assertEqual(sorted(set(KEYS) - bound), [])

    @unittest.skipUnless(SWAY, "sway not installed")
    def test_sway_accepts_the_config_with_its_theme(self):
        with tempfile.TemporaryDirectory() as home:
            config = Path(home) / ".config/sway"
            config.mkdir(parents=True)
            shutil.copy(REPO / "sway/config", config / "config")
            shutil.copy(REPO / "tests/golden/sway-theme.conf", config / "theme.conf")
            (config / "keybinds.conf").write_text(SWAY_KEYS)
            os.chmod(home, 0o700)
            env = {**os.environ, "HOME": home, "XDG_RUNTIME_DIR": home, "WLR_BACKENDS": "headless",
                   "WLR_RENDERER": "pixman", "WLR_LIBINPUT_NO_DEVICES": "1"}
            done = subprocess.run([SWAY, "-C", "-c", str(config / "config")], env=env,
                                  capture_output=True, text=True, timeout=60)
            self.assertEqual(done.returncode, 0, done.stderr[-2000:])


class NiriTest(unittest.TestCase):
    text = (REPO / "niri/config.kdl").read_text() + "\n" + NIRI_KEYS

    def test_every_ipc_call_reaches_a_handler(self):
        handlers = ipc_handlers()
        for target, function in ipc_calls(self.text):
            with self.subTest(call=f"{target} {function}"):
                self.assertIn(function, handlers.get(target, set()))
        self.assertGreaterEqual(len(ipc_calls(self.text)), 14)

    def test_the_usual_keys_are_bound_once(self):
        binds = re.findall(r"^\s+([A-Za-z0-9+_]+)(?:\s+[a-z-]+=\S+)*\s*\{", self.text, re.M)
        binds = [b for b in binds if b not in ("binds", "input", "keyboard", "xkb", "touchpad", "environment",
                                               "hotkey-overlay")]
        self.assertEqual(len(binds), len(set(binds)))
        self.assertEqual(sorted(set(KEYS) - {b.split("+")[-1].lower() if len(b.split("+")[-1]) == 1
                                             else b.split("+")[-1] for b in binds} - {"Return", "Escape", "Print"}), [])

    def test_braces_and_quotes_are_balanced(self):
        for name, text in (("config.kdl", self.text), ("theme.kdl", (REPO / "tests/golden/niri-theme.kdl").read_text())):
            with self.subTest(file=name):
                code = re.sub(r'"(?:[^"\\]|\\.)*"', '""', re.sub(r"//.*", "", text))
                self.assertEqual(code.count("{"), code.count("}"))
                self.assertEqual(code.count('"') % 2, 0)
        self.assertIn('include "theme.kdl"', self.text)
        self.assertIn('include "keybinds.kdl"', self.text)


class InstallerTest(unittest.TestCase):
    def test_wm_packages_only_for_that_wm(self):
        rows = [line.split("\t") for line in (REPO / "install/packages.tsv").read_text().splitlines()
                if line and not line.startswith("#")]
        by_profile = {}
        for row in rows:
            by_profile.setdefault(row[1], []).append(row[0])
        self.assertIn("hyprland", by_profile["wm-hyprland"])
        self.assertIn("sway", by_profile["wm-sway"])
        self.assertIn("niri", by_profile["wm-niri"])


if __name__ == "__main__":
    unittest.main(argv=sys.argv)
