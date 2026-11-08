"""Runs the real shell: Quickshell in a headless sway session, deployed the
way the installer does it (theme.json generated, then the shell files).

The QML tests load the visual parts with plain Qt; only this test loads
the whole shell with Quickshell's own types, so a mistake in a file that
uses them (a property that does not exist, a wrong import) is caught here
instead of on the desktop, where it would leave the screen empty.

Skipped when `qs` or `sway` is not installed (any Wayland compositor with
layer-shell would do; sway runs headless without a GPU).
"""
from __future__ import annotations

import contextlib
import io
import os
import re
import shutil
import subprocess
import tempfile
import time
import unittest
from pathlib import Path

from helpers import REPO, SandboxTest
from theming.generate import main as generate

QS = shutil.which("qs")
SWAY = shutil.which("sway")
SHORTCUTS = (REPO / "quickshell/ipc/Shortcuts.qml").read_text()
# Every IPC target with a toggle(): the panels the keybinds open.
PANELS = re.findall(r'target: "(\w+)"\s*\n\s*function toggle\(\)', SHORTCUTS)
DBUS = shutil.which("dbus-run-session")
# Mistakes in the shell's code. Missing services of the test machine (no
# NetworkManager, PipeWire or Hyprland) are logged too, and are not ours.
CODE_PROBLEMS = ("Failed to load", "caused by", "TypeError", "ReferenceError", "Cannot assign",
                 "Unable to assign", "is not a type", "is not defined", "Cannot read property",
                 "non-existent", "Binding loop")


def problems(log: str) -> list[str]:
    """Lines of a Quickshell log that point at the shell's code."""
    found = []
    for line in log.splitlines():
        in_shell = ".qml[" in line or ".qml:" in line or ".js:" in line
        first_run = "File does not exist" in line    # state files are created later
        if any(text in line for text in CODE_PROBLEMS) or (in_shell and not first_run):
            found.append(line.strip())
    return found


@unittest.skipUnless(QS and SWAY, "needs Quickshell (qs) and sway")
class ShellRuntimeTest(SandboxTest):
    def setUp(self):
        super().setUp()
        # Wayland socket paths must stay short: a runtime folder in /tmp.
        self.runtime = Path(tempfile.mkdtemp(prefix="qs-", dir="/tmp"))
        self.runtime.chmod(0o700)
        self.env.update({"XDG_RUNTIME_DIR": str(self.runtime), "PATH": os.environ.get("PATH", "")})
        # Deployed like install.sh: theme.json, then the shell's files.
        with contextlib.redirect_stdout(io.StringIO()):
            self.assertEqual(generate(["--root", str(REPO), "--only", "quickshell", "--all"], env=self.env), 0)
        self.shell = self.home / ".config/quickshell/desktop"
        shutil.copytree(REPO / "quickshell", self.shell, dirs_exist_ok=True)
        (self.home / "sway.conf").write_text("output HEADLESS-1 mode 1920x1080\n")
        env = {**os.environ, **self.env, "WLR_BACKENDS": "headless", "WLR_LIBINPUT_NO_DEVICES": "1",
               "WLR_RENDERER": "pixman"}
        self.sway = subprocess.Popen([SWAY, "-c", str(self.home / "sway.conf")], env=env,
                                     stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        socket = self.wait_for(lambda: next((p for p in self.runtime.glob("wayland-*") if p.suffix != ".lock"), None))
        self.assertIsNotNone(socket, "sway did not start")
        # No GPU needed: Qt Quick's software renderer.
        self.env.update({"WAYLAND_DISPLAY": socket.name, "QT_QPA_PLATFORM": "wayland", "LC_ALL": "C.UTF-8",
                         "QT_QUICK_BACKEND": "software"})
        self.log = self.home / "qs.log"
        command = [QS, "-c", "desktop", "--no-color"]
        with self.log.open("w") as out:
            self.qs = subprocess.Popen(([DBUS, "--"] if DBUS else []) + command,
                                       env={**os.environ, **self.env}, stdout=out, stderr=subprocess.STDOUT)

    def tearDown(self):
        for process in (self.qs, self.sway):
            process.terminate()
            with contextlib.suppress(subprocess.TimeoutExpired):
                process.wait(timeout=10)
        shutil.rmtree(self.runtime, ignore_errors=True)
        super().tearDown()

    @staticmethod
    def wait_for(check, timeout=20.0):
        deadline = time.monotonic() + timeout
        while time.monotonic() < deadline:
            if result := check():
                return result
            time.sleep(0.2)
        return None

    def read_log(self) -> str:
        return self.log.read_text(errors="replace")

    def ipc(self, target: str, function: str):
        done = subprocess.run([QS, "-c", "desktop", "ipc", "call", target, function],
                              env={**os.environ, **self.env}, capture_output=True, text=True, timeout=20)
        self.assertEqual(done.returncode, 0, f"{target}.{function}: {done.stdout}{done.stderr}")

    def test_the_shell_loads_and_every_panel_opens(self):
        loaded = self.wait_for(lambda: "Configuration Loaded" in self.read_log()
                               or "Failed to load" in self.read_log())
        self.assertTrue(loaded, "the shell did not start:\n" + self.read_log())
        self.assertEqual(problems(self.read_log()), [], "the shell failed to load")
        self.assertGreaterEqual(len(PANELS), 10)
        for panel in PANELS:
            with self.subTest(panel=panel):
                self.ipc(panel, "toggle")   # open
                time.sleep(0.6)
                self.ipc(panel, "toggle")   # close
                time.sleep(0.2)
        self.ipc("bar", "toggleAutohide")
        self.ipc("osd", "brightness")
        time.sleep(0.5)
        self.assertEqual(problems(self.read_log()), [])


if __name__ == "__main__":
    unittest.main()
