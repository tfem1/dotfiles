"""`tfem pick` (color picker) and `tfem updates count`, with stand-in tools:
slurp, grim, wl-copy and notify-send for the picker, checkupdates / apt /
dnf for the updates."""
import shutil
import subprocess
import sys
import unittest

from helpers import REPO, SandboxTest

PPM = r'printf "P6\n1 1\n255\n\072\173\325"'   # one pixel: #3A7BD5


class ToolTest(SandboxTest):
    def setUp(self):
        super().setUp()
        self.bin = self.home / "bin"
        self.bin.mkdir()
        # Only these tools: the real apt or dnf of this machine stay out of reach.
        for tool in ("grep", "awk", "od", "tr", "tail", "head", "mv", "mkdir", "cat", "dirname", "sh"):
            (self.bin / tool).symlink_to(shutil.which(tool))

    def fake(self, name, body):
        (self.bin / name).write_text(f"#!/bin/sh\n{body}\n")
        (self.bin / name).chmod(0o755)

    def run_script(self, script, *args):
        env = {"HOME": str(self.home), "PATH": str(self.bin),
               "XDG_STATE_HOME": str(self.home / "state")}
        return subprocess.run([shutil.which("bash"), str(REPO / "scripts" / script), *args], env=env,
                              capture_output=True, text=True, timeout=20)


class PickTest(ToolTest):
    def setUp(self):
        super().setUp()
        self.fake("slurp", 'echo "10,20 1x1"')
        self.fake("grim", f'echo "$@" > {self.home}/grim.args; {PPM}')
        self.fake("wl-copy", f"cat > {self.home}/clipboard")
        self.fake("notify-send", "true")

    def test_the_pixel_color_is_copied_and_kept_once(self):
        for _ in range(2):
            done = self.run_script("pick.sh")
            self.assertEqual((done.returncode, done.stdout.strip()), (0, "#3A7BD5"))
        self.assertEqual((self.home / "clipboard").read_text(), "#3A7BD5")
        self.assertEqual((self.home / "grim.args").read_text().split(), ["-s", "1", "-g", "10,20", "1x1", "-t", "ppm", "-"])
        self.assertEqual(self.run_script("pick.sh", "history").stdout, "#3A7BD5\n")

    def test_escape_in_slurp_picks_nothing(self):
        self.fake("slurp", "exit 1")
        self.assertEqual(self.run_script("pick.sh").returncode, 0)
        self.assertFalse((self.home / "clipboard").exists())


class UpdatesTest(ToolTest):
    def count(self):
        return self.run_script("updates.sh", "count").stdout.strip()

    def test_arch_counts_checkupdates_lines(self):
        self.fake("checkupdates", 'printf "linux 6.1 -> 6.2\\nfirefox 1 -> 2\\n"')
        self.assertEqual(self.count(), "2")

    def test_nothing_to_update_is_zero(self):
        self.fake("checkupdates", "exit 2")
        self.assertEqual(self.count(), "0")

    def test_debian_counts_upgradable_packages(self):
        self.fake("apt", 'printf "Listing...\\nvim/stable 9.1 amd64 [upgradable from: 9.0]\\n"')
        self.assertEqual(self.count(), "1")

    def test_fedora_counts_until_the_obsoleting_part(self):
        self.fake("dnf", 'printf "kernel.x86_64 6.2 updates\\nvim.x86_64 9.1 updates\\n\\nObsoleting Packages\\nold.x86_64 1 updates\\n"; exit 100')
        self.assertEqual(self.count(), "2")


if __name__ == "__main__":
    unittest.main(argv=sys.argv)
