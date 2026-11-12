"""Tests of install.sh with fake package managers, os-release files and Hyprland."""
import os
import subprocess
import tempfile
import unittest
from pathlib import Path

from helpers import REPO, fake_fairywren

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
    "systemctl": 'echo "systemctl $*" >> "$LOG"',
    # OpenBSD: `pkg_info -Q NAME` lists NAME-version unless it is missing.
    "pkg_info": f'[ "$1" = -Q ] && {{ ( {AVAILABLE} ) && echo "$2-1.0"; }}; exit 0',
    "pkg_add": 'echo "pkg_add $*" >> "$LOG"',
    "doas": 'exec "$@"',
}
# Where `tfem sddm install` writes, as TFEM_<name> paths under self.system.
SYSTEM = {
    "SDDM_THEMES": "usr/share/sddm/themes", "SDDM_CONF": "etc/sddm.conf.d/zz-login-theme.conf",
    "SDDM_MAIN_CONF": "etc/sddm.conf", "SDDM_DIR": "var/lib/tfem/sddm",
    "DM_LINK": "etc/systemd/system/display-manager.service",
}
OS_RELEASE = {
    "arch": 'ID=arch\n',
    "mint": 'ID=linuxmint\nID_LIKE="ubuntu debian"\n',
    "nobara": 'ID=nobara\nID_LIKE="rhel fedora"\n',
    "gentoo": 'ID=gentoo\n',
    "openbsd": "",   # no os-release: told apart by uname
}


class InstallTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls._icons = tempfile.TemporaryDirectory()
        cls.fairywren = fake_fairywren(Path(cls._icons.name) / "FairyWren-Icons")

    @classmethod
    def tearDownClass(cls):
        cls._icons.cleanup()

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
        self.system = self.home / "system"

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
            "TFEM_UNAME": "OpenBSD" if distro == "openbsd" else "Linux",
            "TFEM_OS_RELEASE": str(release), "XDG_CONFIG_HOME": str(self.home / ".config"),
            "XDG_STATE_HOME": str(self.home / ".local/state"), "XDG_DATA_HOME": str(self.home / ".local/share"),
            # Icons from a local stand-in: the tests never download the real ones.
            "TFEM_FAIRYWREN_URL": self.fairywren,
            # The login screen goes to a fake system under the sandbox.
            **{f"TFEM_{name}": str(self.system / path) for name, path in SYSTEM.items()},
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
        for name in ("hyprland", "quickshell", "satty", "bluez-utils", "ttf-jetbrains-mono-nerd", "sddm", "cava", "gamemode"):
            self.assertIn(f" {name}", command)

    def test_no_sddm_leaves_the_package_out(self):
        self.install("arch", "--yes", "--no-wallpapers", "--no-sddm")
        self.assertNotIn(" sddm", self.installed("pacman -S --needed"))

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
        self.assertIn(" sddm qml6-module-qtquick-effects", command)  # the theme's effects, apart on Debian
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

    def test_openbsd_gets_the_apps_and_their_themes_not_the_desktop(self):
        # pkg_info is asked for python-3.13: not in this repository.
        code, output = self.install("openbsd", "--yes", "--no-wallpapers", missing="python-3.13", hyprland=False)
        self.assertEqual(code, 0, output)
        command = self.installed("pkg_add -I")
        for name in (" python%3.12", " kitty", " qt6ct", " papirus-icon-theme", " glib2"):
            self.assertIn(name, command)
        self.assertNotIn("python%3.13", command)            # the first available python branch
        self.assertIn("not in the official openbsd repositories: hyprland hyprlock hypridle quickshell", output)
        self.assertIn("OpenBSD has no Hyprland nor Quickshell yet", output)
        self.assertFalse((self.home / ".config/hypr").exists())             # no desktop to set up
        self.assertFalse((self.home / ".config/quickshell").exists())
        self.assertNotIn("sddm", self.calls())
        self.assertIn("generating the theme files", output)                 # the themes, for the apps
        self.assertIn("your apps follow the theme", output)
        self.assertEqual(Path(os.readlink(self.home / ".local/bin/tfem")), REPO / "tfem")

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

    def test_install_downloads_the_icons_with_the_theme_folder_color(self):
        code, output = self.install("arch", "--yes", "--no-wallpapers", "--no-packages")
        self.assertEqual(code, 0, output)
        icons = self.home / ".local/share/icons"
        for theme in ("FairyWren_Dark", "FairyWren_Light"):
            self.assertTrue((icons / theme / "index.theme").is_file())
            # Moonlit's accent is teal: generate pointed the folders there.
            self.assertEqual(os.readlink(icons / theme / "places/colours/default"), "./teal")
        self.assertFalse((icons / "README.md").exists())

    def test_the_stacked_clock_login_screen_is_installed_and_turned_on(self):
        code, output = self.install("arch", "--yes", "--no-wallpapers", "--no-packages")
        self.assertEqual(code, 0, output)
        self.assertTrue((self.system / "usr/share/sddm/themes/stacked-clock/Main.qml").is_file())
        self.assertIn("Current=stacked-clock", (self.system / "etc/sddm.conf.d/zz-login-theme.conf").read_text())
        self.assertTrue((self.system / "var/lib/tfem/sddm/theme.conf").is_file())  # kept by generate
        self.assertIn("systemctl enable sddm.service", self.calls())

    def test_sddm_options_pick_or_skip_the_login_screen(self):
        code, output = self.install("arch", "--dry-run", "--sddm", "welcome-panel")
        self.assertEqual(code, 0, output)
        self.assertIn("sddm install welcome-panel --enable", output)
        _, output = self.install("arch", "--dry-run", "--no-sddm")
        self.assertNotIn("sddm install", output)
        code, _ = self.install("arch", "--dry-run", "--sddm", "nope")
        self.assertEqual(code, 64)

    def test_no_icons_skips_the_download(self):
        code, _ = self.install("arch", "--yes", "--no-wallpapers", "--no-packages", "--no-icons")
        self.assertEqual(code, 0)
        self.assertFalse((self.home / ".local/share/icons/FairyWren_Dark").exists())

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

    def test_sway_or_niri_get_their_config_instead_of_hyprland(self):
        for wm, folder, main in (("sway", "sway", "config"), ("niri", "niri", "config.kdl")):
            with self.subTest(wm=wm):
                code, output = self.install("arch", "--yes", "--no-wallpapers", "--no-packages", "--no-sddm", "--wm", wm)
                self.assertEqual(code, 0, output)
                self.assertEqual(self.config(f"{folder}/{main}").read_text(), (REPO / folder / main).read_text())
                self.assertIn(f"window manager: {wm}", output)
        self.assertFalse(self.config("hypr/hyprland.lua").exists())

    def test_the_wm_decides_which_packages(self):
        self.install("arch", "--yes", "--no-wallpapers", "--wm", "sway")
        command = self.installed("pacman -S --needed --noconfirm")
        self.assertIn(" sway", command)
        self.assertIn(" swaylock", command)
        self.assertNotIn(" hyprland", command)
        self.assertNotIn(" hyprlock", command)

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
        code, output = self.install("arch", "--uninstall")
        self.assertEqual(code, 0)
        self.assertEqual(self.config("hypr/hyprland.lua").read_text(), "-- mine\n")
        self.assertIn("kept: the login screen", output)  # system files: removed by hand, with sudo
        self.assertFalse((self.home / ".local/bin/tfem").exists())
        self.assertFalse(self.config("quickshell/desktop").exists())  # created by the install


if __name__ == "__main__":
    unittest.main()
