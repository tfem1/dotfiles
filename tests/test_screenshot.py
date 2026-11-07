"""Tests of scripts/screenshot.sh with fake grim, slurp, satty and wl-copy."""
import os
import subprocess
import tempfile
import unittest
from pathlib import Path

from helpers import REPO

SCRIPT = REPO / "scripts/screenshot.sh"

# Each fake tool appends its arguments to calls.log; grim writes a fake image.
FAKES = {
    "slurp": 'echo "slurp $*" >> "$LOG"; [ -n "$SLURP_CANCEL" ] && exit 1; echo "10,20 300x200"',
    "grim": 'echo "grim $*" >> "$LOG"; out="${@: -1}"; [ "$out" = - ] && echo PNG || echo PNG > "$out"',
    "satty": 'echo "satty $*" >> "$LOG"; cat > /dev/null',
    "wl-copy": 'echo "wl-copy $*" >> "$LOG"; cat > /dev/null',
}


class ScreenshotTest(unittest.TestCase):
    def setUp(self):
        self._tmp = tempfile.TemporaryDirectory()
        self.root = Path(self._tmp.name)
        bin_dir = self.root / "bin"
        bin_dir.mkdir()
        for name, body in FAKES.items():
            tool = bin_dir / name
            tool.write_text(f"#!/usr/bin/env bash\n{body}\n")
            tool.chmod(0o755)
        self.log = self.root / "calls.log"
        self.pictures = self.root / "Pictures"
        self.env = {**os.environ, "PATH": f"{bin_dir}:{os.environ['PATH']}",
                    "LOG": str(self.log), "XDG_PICTURES_DIR": str(self.pictures)}

    def tearDown(self):
        self._tmp.cleanup()

    def run_script(self, *args, **env):
        return subprocess.run([str(SCRIPT), *args], env={**self.env, **env}, capture_output=True, text=True)

    def calls(self):
        return self.log.read_text().splitlines() if self.log.exists() else []

    def shots(self):
        return list((self.pictures / "Screenshots").glob("*.png"))

    def test_region_is_saved_and_copied(self):
        self.assertEqual(self.run_script("region").returncode, 0)
        self.assertEqual(len(self.shots()), 1)
        self.assertTrue(any(c.startswith("grim -g 10,20 300x200 ") for c in self.calls()))
        self.assertIn("wl-copy --type image/png", self.calls())

    def test_full_screen_skips_the_selection(self):
        self.run_script("full")
        self.assertFalse(any(c.startswith("slurp") for c in self.calls()))
        self.assertEqual(len(self.shots()), 1)

    def test_cancelled_selection_does_nothing(self):
        done = self.run_script("region", SLURP_CANCEL="1")
        self.assertEqual(done.returncode, 0)
        self.assertEqual(self.shots(), [])

    def test_edit_opens_satty_with_the_target_file(self):
        self.run_script("full", "--edit")
        satty = [c for c in self.calls() if c.startswith("satty")]
        self.assertEqual(len(satty), 1)
        self.assertIn("--filename - --output-filename", satty[0])
        self.assertIn(str(self.pictures / "Screenshots"), satty[0])

    def test_edit_without_satty_still_saves_the_capture(self):
        (self.root / "bin/satty").unlink()
        self.env["PATH"] = f"{self.root / 'bin'}:/usr/bin:/bin"
        done = self.run_script("full", "--edit")
        self.assertEqual(done.returncode, 0)
        self.assertIn("satty is not installed", done.stderr)
        self.assertEqual(len(self.shots()), 1)

    def test_bad_arguments_are_refused(self):
        self.assertEqual(self.run_script("everything").returncode, 64)
        self.assertEqual(self.run_script("full", "--paint").returncode, 64)


if __name__ == "__main__":
    unittest.main()
