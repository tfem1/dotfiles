"""Tests of install.sh with fake package managers, os-release files and Hyprland."""
import os
import subprocess
import tempfile
import unittest
from pathlib import Path

from helpers import REPO

# Fake tools log their arguments; a package is available unless listed in $MISSING.
AVAILABLE = 'for p in $MISSING; do [ "$p" = "${!#}" ] && exit 1; done; exit 0'
FAKES = {
    "sudo": 'exec "$@"',
    "pacman": f'echo "pacman $*" >> "$LOG"; [ "$1" = -Si ] && {{ {AVAILABLE}; }}; exit 0',
    # Mimics `apt-cache policy`: a missing package has the candidate "(none)".
    "apt-cache": f'if ( {AVAILABLE} ); then echo "  Candidate: 1.0"; else echo "  Candidate: (none)"; fi',
    "apt-get": 'echo "apt-get $*" >> "$LOG"',
    "apt": 'echo "apt $*" >> "$LOG"',
    "dnf": f'echo "dnf $*" >> "$LOG"; [ "$1" = info ] && {{ {AVAILABLE}; }}; exit 0',
    "hyprctl": 'echo "hyprctl $*" >> "$LOG"',
}
OS_RELEASE = {
    "arch": 'ID=arch\n',
    "mint": 'ID=linuxmint\nID_LIKE="ubuntu debian"\n',
    "nobara": 'ID=nobara\nID_LIKE="rhel fedora"\n',
    "gentoo": 'ID=gentoo\n',
}


class InstallTest(unittest.TestCase):
    def setUp(self):
        self._tmp = tempfile.TemporaryDirectory()
        self.home = Path(self._tmp.name)
        self.fake_bin = self.home / "fake-bin"
        self.hypr_bin = self.home / "hypr-bin"
        for folder in (self.fake_bin, self.hypr_bin):
            folder.mkdir()
        for name, body in FAKES.items():
            self.write_tool(self.fake_bin / name, body)
        self.set_hyprland("0.57.1")
        self.write_tool(self.hypr_bin / "qs", 'echo "qs $*" >> "$LOG"')  # Quickshell is installed
        self.log = self.home / "calls.log"

    def tearDown(self):
        self._tmp.cleanup()

    @staticmethod
    def write_tool(path, body):
        path.write_text(f"#!/usr/bin/env bash\n{body}\n")
        path.chmod(0o755)

    def set_hyprland(self, version):
        self.write_tool(self.hypr_bin / "Hyprland", f'echo "Hyprland {version} built from branch main"')

    def install(self, distro, *args, missing="", hyprland=True):
        release = self.home / f"os-release-{distro}"
        release.write_text(OS_RELEASE[distro])
        path = [str(self.fake_bin)] + ([str(self.hypr_bin)] if hyprland else []) + ["/usr/bin", "/bin"]
        env = {
            "HOME": str(self.home), "PATH": ":".join(path), "LOG": str(self.log), "MISSING": missing,
            "TFEM_OS_RELEASE": str(release), "XDG_CONFIG_HOME": str(self.home / ".config"),
            "XDG_STATE_HOME": str(self.home / ".local/state"), "XDG_DATA_HOME": str(self.home / ".local/share"),
        }
        done = subprocess.run(["bash", str(REPO / "install.sh"), *args], env=env,
                              capture_output=True, text=True, timeout=120)
        return done.returncode, done.stdout + done.stderr

    def calls(self):
        return self.log.read_text() if self.log.exists() else ""

    def installed(self, manager_prefix):
        return next((line for line in self.calls().splitlines() if line.startswith(manager_prefix)), "")


class PackagesTest(InstallTest):
    def test_arch_installs_the_full_profile_with_pacman(self):
        code, _ = self.install("arch", "--yes", "--no-wallpapers")
        self.assertEqual(code, 0)
        command = self.installed("pacman -S --needed --noconfirm")
        for name in ("hyprland", "quickshell", "satty", "bluez-utils", "ttf-jetbrains-mono-nerd"):
            self.assertIn(f" {name}", command)

    def test_minimal_profile_leaves_out_apps_and_wallpapers(self):
        code, output = self.install("arch", "--yes", "--profile", "minimal")
        self.assertEqual(code, 0)
        self.assertNotIn("firefox", self.installed("pacman -S"))
        self.assertNotIn("wallpapers", output.lower().split("generating")[0].replace("pictures/wallpapers", ""))

    def test_debian_family_takes_the_first_available_alternative(self):
        self.install("mint", "--yes", "--no-wallpapers", missing="firefox-esr")
        command = self.installed("apt install -y")
        self.assertIn(" firefox", command)
        self.assertNotIn("firefox-esr", command)
        self.assertIn("apt-get update", self.calls())

    def test_missing_packages_are_skipped_not_fatal(self):
        code, output = self.install("mint", "--yes", "--no-wallpapers", missing="cliphist")
        self.assertEqual(code, 0)
        self.assertIn("skipped: cliphist", output)
        self.assertNotIn("cliphist", self.installed("apt install -y"))

    def test_fedora_points_to_a_copr_when_hyprland_is_missing(self):
        code, output = self.install("nobara", "--yes", "--no-wallpapers", hyprland=False)
        self.assertEqual(code, 0)
        self.assertIn("not in the official fedora repositories: hyprland hyprlock", output)
        self.assertIn("sudo dnf copr enable", output)
        self.assertIn("dnf install -y", self.calls())

    def test_old_hyprland_is_reported(self):
        self.set_hyprland("0.53.3")
        _, output = self.install("arch", "--yes", "--no-wallpapers", "--no-packages")
        self.assertIn("Hyprland 0.53.3 is too old", output)

    def test_unknown_distro_is_refused(self):
        code, output = self.install("gentoo", "--yes")
        self.assertEqual(code, 1)
        self.assertIn("unsupported distribution 'gentoo'", output)


class DeployTest(InstallTest):
    def config(self, *parts):
        return self.home.joinpath(".config", *parts)

    def test_dry_run_changes_nothing(self):
        code, output = self.install("arch", "--dry-run")
        self.assertEqual(code, 0)
        self.assertIn("[dry-run]", output)
        self.assertFalse(self.config("hypr").exists())
        self.assertNotIn("pacman -S --needed", self.calls())

    def test_install_backs_up_then_deploys_links_and_generates(self):
        self.config("hypr").mkdir(parents=True)
        self.config("hypr/hyprland.lua").write_text("-- mine\n")
        code, _ = self.install("arch", "--yes", "--no-wallpapers", "--no-packages")
        self.assertEqual(code, 0)
        backups = list((self.home / ".local/state/tfem/backups").rglob("hyprland.lua"))
        self.assertEqual([b.read_text() for b in backups], ["-- mine\n"])
        self.assertEqual(self.config("hypr/hyprland.lua").read_text(), (REPO / "hypr/hyprland.lua").read_text())
        self.assertTrue(self.config("hypr/theme.lua").exists())
        self.assertTrue(self.config("quickshell/desktop/shell.qml").exists())
        self.assertTrue(self.config("quickshell/desktop/theme.json").exists())
        self.assertEqual(Path(os.readlink(self.home / ".local/bin/tfem")), REPO / "tfem")

    def test_someone_elses_command_is_not_replaced(self):
        bin_dir = self.home / ".local/bin"
        bin_dir.mkdir(parents=True)
        (bin_dir / "wm").write_text("#!/bin/sh\n")
        _, output = self.install("arch", "--yes", "--no-wallpapers", "--no-packages")
        self.assertEqual((bin_dir / "wm").read_text(), "#!/bin/sh\n")
        self.assertIn("is not ours", output)

    def test_uninstall_restores_the_previous_config(self):
        self.config("hypr").mkdir(parents=True)
        self.config("hypr/hyprland.lua").write_text("-- mine\n")
        self.install("arch", "--yes", "--no-wallpapers", "--no-packages")
        self.install("arch", "--yes", "--no-wallpapers", "--no-packages")  # an update in between
        code, _ = self.install("arch", "--uninstall")
        self.assertEqual(code, 0)
        self.assertEqual(self.config("hypr/hyprland.lua").read_text(), "-- mine\n")
        self.assertFalse((self.home / ".local/bin/tfem").exists())
        self.assertFalse(self.config("quickshell/desktop").exists())  # created by the install


if __name__ == "__main__":
    unittest.main()
