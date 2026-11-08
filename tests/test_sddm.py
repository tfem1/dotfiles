"""SDDM login screens: the build (theme.conf, wallpaper, shared parts), the
install (into a sandbox, without sudo), and both themes loaded with stand-ins
for what SDDM gives them, down to the login call and a wrong password."""
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

from helpers import REPO, SandboxTest

sys.path.insert(0, str(REPO / "scripts"))
from sddm import THEMES, build  # noqa: E402

try:
    from PySide6.QtCore import Property, QObject, Qt, QUrl, Signal, Slot
    from PySide6.QtGui import QGuiApplication, QStandardItem, QStandardItemModel
    from PySide6.QtQml import QQmlComponent, QQmlEngine, QQmlPropertyMap
except ImportError:
    QGuiApplication = None

PNG = bytes.fromhex("89504e470d0a1a0a0000000d4948445200000001000000010806000000"
                    "1f15c4890000000d49444154789c6360f8cfc0000003010100c9fe92ef"
                    "0000000049454e44ae426082")


def conf(path: Path) -> dict[str, str]:
    lines = [line.split("=", 1) for line in path.read_text().splitlines() if "=" in line]
    return {key: value for key, value in lines}


class BuildTest(SandboxTest):
    def test_every_theme_is_built_with_its_parts_and_colors(self):
        for name in THEMES:
            with self.subTest(theme=name):
                dest = build(name, self.home / "out" / name, self.paths)
                for part in ("Main.qml", "metadata.desktop", "theme.conf", "common/Icon.qml",
                             "common/icons.js", "common/PasswordField.qml"):
                    self.assertTrue((dest / part).is_file(), part)
                self.assertIn("QtVersion=6", (dest / "metadata.desktop").read_text())
                values = conf(dest / "theme.conf")
                self.assertEqual(values["accent"], "#d19fe4")   # Twilight
                self.assertEqual(values["background"], "")       # no wallpaper set
                self.assertEqual(values["font"], "Inter")

    def test_the_wallpaper_is_copied_next_to_the_theme(self):
        image = self.home / "Pictures/Wallpapers/pony/luna.png"
        image.parent.mkdir(parents=True)
        image.write_bytes(PNG)
        self.write_user_file("theme.toml", '[wallpaper]\npath = "pony/luna.png"\n[palette]\nsource = "pony-luna"\n')
        dest = build("stacked-clock", self.home / "out", self.paths)
        self.assertEqual(conf(dest / "theme.conf")["background"], "background.png")
        self.assertEqual((dest / "background.png").read_bytes(), PNG)
        self.assertIn("from Luna", (dest / "theme.conf").read_text())

    def test_unknown_theme_is_refused(self):
        with self.assertRaisesRegex(ValueError, "unknown login theme"):
            build("nope", self.home / "out", self.paths)


class InstallTest(SandboxTest):
    def install(self, *args, main_conf=""):
        system = self.home / "system"
        (system / "etc").mkdir(parents=True)
        if main_conf:
            (system / "etc/sddm.conf").write_text(main_conf)
        env = {**os.environ, **self.env, "TFEM_SUDO": "", "TFEM_SDDM_THEMES": str(system / "themes"),
               "TFEM_SDDM_CONF": str(system / "etc/sddm.conf.d/zz-login-theme.conf"),
               "TFEM_SDDM_MAIN_CONF": str(system / "etc/sddm.conf"), "PATH": "/usr/bin:/bin"}
        done = subprocess.run([sys.executable, str(REPO / "scripts/sddm.py"), "install", *args], env=env,
                              capture_output=True, text=True, timeout=60)
        return done.returncode, done.stdout + done.stderr, system

    def test_install_copies_the_theme_and_selects_it(self):
        code, output, system = self.install("stacked-clock")
        self.assertEqual(code, 0, output)
        self.assertTrue((system / "themes/stacked-clock/Main.qml").is_file())
        self.assertIn("Current=stacked-clock", (system / "etc/sddm.conf.d/zz-login-theme.conf").read_text())
        self.assertIn("SDDM is not installed", output)

    def test_a_theme_forced_by_sddm_conf_is_reported(self):
        code, output, _ = self.install(main_conf="[Theme]\nCurrent=breeze\n")
        self.assertEqual(code, 0, output)
        self.assertIn("selects 'breeze'", output)


if QGuiApplication is not None:
    class Proxy(QObject):
        """Stands in for SDDM's `sddm` object: remembers the login calls."""
        loginFailed = Signal()
        loginSucceeded = Signal()

        def __init__(self):
            super().__init__()
            self.calls = []

        hostName = Property(str, lambda self: "ponyville", constant=True)
        canPowerOff = Property(bool, lambda self: True, constant=True)
        canReboot = Property(bool, lambda self: True, constant=True)
        canSuspend = Property(bool, lambda self: True, constant=True)

        @Slot(str, str, int)
        def login(self, user, password, session):
            self.calls.append((user, password, session))

        @Slot()
        def powerOff(self):
            pass

        @Slot()
        def reboot(self):
            pass

        @Slot()
        def suspend(self):
            pass

    class Model(QStandardItemModel):
        """A user or session model with SDDM's role names and lastIndex."""

        def __init__(self, roles, rows, last):
            super().__init__()
            self._last = last
            self.setItemRoleNames({Qt.UserRole + i: role.encode() for i, role in enumerate(roles)})
            for row in rows:
                item = QStandardItem()
                for i, value in enumerate(row):
                    item.setData(value, Qt.UserRole + i)
                self.appendRow(item)

        lastIndex = Property(int, lambda self: self._last, constant=True)
        count = Property(int, lambda self: self.rowCount(), constant=True)

    class Keyboard(QObject):
        capsLock = Property(bool, lambda self: False, constant=True)


@unittest.skipIf(QGuiApplication is None, "PySide6 not installed")
class ThemeTest(SandboxTest):
    @classmethod
    def setUpClass(cls):
        cls.app = QGuiApplication.instance() or QGuiApplication(sys.argv[:1])

    def load(self, name):
        dest = build(name, Path(tempfile.mkdtemp(dir=self.home)) / name, self.paths)
        self.engine = QQmlEngine()
        self.proxy = Proxy()
        self.users = Model(("name", "realName", "homeDir", "icon", "needsPassword"),
                           [("twilight", "Twilight Sparkle", "/home/twilight", "", True),
                            ("luna", "", "/home/luna", "", True)], 1)
        self.sessions = Model(("directory", "file", "type", "name", "exec", "comment"),
                              [("", "hyprland.desktop", "wayland", "Hyprland", "Hyprland", "")], 0)
        self.keyboard = Keyboard()
        self.config = QQmlPropertyMap()
        for key, value in conf(dest / "theme.conf").items():
            self.config.insert(key, value)
        context = self.engine.rootContext()
        for key, value in (("sddm", self.proxy), ("userModel", self.users), ("sessionModel", self.sessions),
                           ("keyboard", self.keyboard), ("config", self.config)):
            context.setContextProperty(key, value)
        # Kept on the test: the screen goes away with its component.
        self.component = QQmlComponent(self.engine, QUrl.fromLocalFile(str(dest / "Main.qml")))
        self.root = self.component.create()
        self.assertEqual([error.toString() for error in self.component.errors()], [])
        self.assertIsNotNone(self.root)
        return self.root

    def test_both_themes_sign_in_the_shown_user_and_report_a_wrong_password(self):
        for name in THEMES:
            with self.subTest(theme=name):
                root = self.load(name)
                password = root.findChild(QObject, "password")
                password.setProperty("text", "friendship")
                root.metaObject().invokeMethod(root, "login")
                # Luna signed in last (lastIndex 1), into the only session.
                self.assertEqual(self.proxy.calls, [("luna", "friendship", 0)])
                self.proxy.loginFailed.emit()
                self.assertEqual(root.property("error"), "Wrong password, try again")
                self.assertEqual(password.property("text"), "")


if __name__ == "__main__":
    unittest.main()
