"""The install screen (install/tui.sh), driven with keys from a file."""
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

from helpers import REPO

SETUP = ("FAMILY=arch ROOT=/x DESKTOP=1 WITH_PACKAGES=1 WITH_WALLPAPERS=1 WITH_ICONS=1 WITH_FONTS=1 "
         "SDDM_THEME=stacked-clock; . install/tui.sh; ")
REPORT = 'echo "rc=$rc $WITH_PACKAGES $WITH_WALLPAPERS $WITH_ICONS $WITH_FONTS ${SDDM_THEME:-none}"'


def run(keys: str, script: str = "tui_run >/dev/null; rc=$?; ") -> str:
    with tempfile.TemporaryDirectory() as folder:
        tty = Path(folder) / "keys"
        tty.write_text(keys)
        done = subprocess.run(["bash", "-c", f"TFEM_TTY={tty}; " + SETUP + script + REPORT],
                              cwd=REPO, capture_output=True, text=True, timeout=10)
    return done.stdout.strip().splitlines()[-1]


class TuiTest(unittest.TestCase):
    def test_the_banner_says_tfem_and_lists_the_choices(self):
        done = subprocess.run(["bash", "-c", SETUP + "tui_draw"], cwd=REPO, capture_output=True, text=True)
        self.assertIn("████████╗███████╗███████╗███╗   ███╗", done.stdout)
        for label in ("Packages", "Wallpapers", "Icons", "Monocraft", "Login screen", "< stacked-clock >"):
            self.assertIn(label, done.stdout)

    def test_enter_keeps_everything_on(self):
        self.assertEqual(run("\n"), "rc=0 1 1 1 1 stacked-clock")

    def test_keys_turn_choices_off_and_pick_the_login_screen(self):
        # Down to Wallpapers, off; down to Icons, off; up past the top to the
        # login screen (last row), right twice: welcome-panel, then none.
        self.assertEqual(run("j j kkkll\n"), "rc=0 1 0 0 1 none")

    def test_arrow_keys_work_too(self):
        self.assertEqual(run("\033[B \n"), "rc=0 1 0 1 1 stacked-clock")

    def test_q_quits_without_installing(self):
        self.assertEqual(run("jq"), "rc=1 1 1 1 1 stacked-clock")

    def test_no_screen_with_yes_or_dry_run_or_no_tui(self):
        for flags in ("ASSUME_YES=1 DRY_RUN=0 WITH_TUI=1", "ASSUME_YES=0 DRY_RUN=1 WITH_TUI=1",
                      "ASSUME_YES=0 DRY_RUN=0 WITH_TUI=0"):
            with self.subTest(flags=flags):
                line = run("", f"{flags}; tui_wanted; rc=$?; ")
                self.assertTrue(line.startswith("rc=1"), line)


if __name__ == "__main__":
    unittest.main(argv=sys.argv)
