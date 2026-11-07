"""QML checks, run when PySide6 is installed (pip install PySide6-Essentials).

The visual components are plain QtQuick and are loaded for real; the files
that need Quickshell (windows, services) go through qmllint for syntax.
"""
import os
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

from helpers import REPO

try:
    os.environ.setdefault("QT_QPA_PLATFORM", "offscreen")
    os.environ.setdefault("QT_QUICK_BACKEND", "software")
    from PySide6.QtCore import QUrl
    from PySide6.QtGui import QGuiApplication
    from PySide6.QtQml import QQmlComponent, QQmlEngine
except ImportError:
    QGuiApplication = None

SHELL = REPO / "quickshell"
VISUAL = [
    "components/Icon.qml", "components/Label.qml", "components/Pill.qml",
    "components/RingProgress.qml", "components/NotchCorner.qml",
    "bar/BarContent.qml", "bar/Workspaces.qml", "bar/MediaChip.qml", "bar/ClockChip.qml",
    "bar/StatusArea.qml", "osd/OsdContent.qml",
    "notifications/NotificationCard.qml", "launcher/LauncherContent.qml", "launcher/LauncherItem.qml",
]


@unittest.skipIf(QGuiApplication is None, "PySide6 not installed")
class VisualComponentsTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.app = QGuiApplication.instance() or QGuiApplication(sys.argv[:1])
        cls.engine = QQmlEngine()

    def test_every_visual_component_loads_without_errors(self):
        for name in VISUAL:
            with self.subTest(component=name):
                component = QQmlComponent(self.engine, QUrl.fromLocalFile(str(SHELL / name)))
                instance = component.create()
                self.assertEqual([e.toString() for e in component.errors()], [])
                self.assertIsNotNone(instance)

    def test_preview_renders_a_desktop_and_the_launcher(self):
        with tempfile.TemporaryDirectory() as out:
            done = subprocess.run([sys.executable, str(REPO / "tools/preview/render.py"), "--out", out],
                                  capture_output=True, text=True, timeout=120)
            self.assertEqual(done.returncode, 0, done.stderr)
            self.assertEqual(sorted(p.name for p in Path(out).iterdir()),
                             ["pony-twilight-bar.png", "pony-twilight-desktop.png", "pony-twilight-launcher.png"])


QMLLINT = shutil.which("pyside6-qmllint", path=os.path.dirname(sys.executable)) or shutil.which("qmllint")


@unittest.skipUnless(QMLLINT, "qmllint not installed")
class SyntaxTest(unittest.TestCase):
    def test_no_syntax_error_in_the_shell(self):
        files = sorted(str(p) for p in SHELL.rglob("*.qml"))
        done = subprocess.run([QMLLINT, *files], capture_output=True, text=True)
        errors = [line for line in (done.stdout + done.stderr).splitlines() if "Error:" in line]
        self.assertEqual(errors, [])


if __name__ == "__main__":
    unittest.main()
