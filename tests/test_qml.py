"""QML checks, run when PySide6 is installed (pip install PySide6-Essentials).

The visual components are plain QtQuick and are loaded for real; the files
that need Quickshell (windows, services) go through qmllint for syntax.
"""
import json
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
    "components/SearchField.qml", "clipboard/ClipboardContent.qml",
    "cheatsheet/CheatsheetContent.qml", "cheatsheet/KeyRow.qml",
    "wallpaper/SelectorContent.qml", "wallpaper/SelectorToolbar.qml", "wallpaper/Carousel.qml",
    "wallpaper/SlantedCard.qml", "wallpaper/Backdrop.qml",
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
            modes = ["bar", "cheatsheet", "clipboard", "desktop", "launcher", "wallpaper"]
            self.assertEqual(sorted(p.name for p in Path(out).iterdir()), [f"pony-twilight-{m}.png" for m in modes])

    def probe(self, script, expression, value):
        """Evaluates `expression` (with `input` = value) against a JS file of the shell."""
        component = QQmlComponent(self.engine)
        component.setData(f'import QtQml\nimport "{script.name}" as Lib\n'
                          f'QtObject {{ property var input; readonly property var result: {expression} }}'.encode(),
                          QUrl.fromLocalFile(str(script.with_name("Probe.qml"))))
        probe = component.createWithInitialProperties({"input": value})
        self.assertEqual([e.toString() for e in component.errors()], [])
        result = probe.property("result")
        return result.toVariant() if hasattr(result, "toVariant") else result

    def test_launcher_search_ranks_and_matches_every_field(self):
        apps = [
            {"name": "Files", "genericName": "File Manager", "comment": "Access and organize files",
             "keywords": ["folder", "manager"], "id": "org.gnome.Nautilus", "command": ["nautilus", "--new-window"]},
            {"name": "Firefox", "genericName": "Web Browser", "comment": "Browse the World Wide Web",
             "keywords": ["Internet", "WWW"], "id": "firefox", "command": ["firefox"]},
            {"name": "kitty", "genericName": "Terminal emulator", "comment": "Fast GPU based terminal",
             "keywords": [], "id": "kitty", "command": ["kitty"]},
            {"name": "btop++", "genericName": "System Monitor", "comment": "Resource monitor",
             "keywords": ["system", "monitor"], "id": "btop", "command": ["btop"]},
            {"name": "Hidden helper", "noDisplay": True, "id": "helper", "command": ["helper"]},
        ]
        search = SHELL / "launcher/search.js"
        cases = {"": ["btop++", "Files", "Firefox", "kitty"], "fi": ["Files", "Firefox"], "ox": ["Firefox"],
                 "nautilus": ["Files"], "term": ["kitty"], "web brow": ["Firefox"], "zzz": [], "help": []}
        for query, expected in cases.items():
            with self.subTest(query=query):
                names = self.probe(search, f'Lib.rank(input, {json.dumps(query)}, 50).map(app => app.name)', apps)
                self.assertEqual(names, expected)

    def test_wallpaper_filters_by_color_recent_and_search(self):
        images = [{"path": f"/w/{c}/{n}.jpg", "name": n, "category": c}
                  for c, n in (("forest", "moss"), ("pony", "twilight #1"), ("pony", "luna"))]
        colors = {"/w/forest/moss.jpg": "green", "/w/pony/twilight #1.jpg": "purple", "/w/pony/luna.jpg": "blue"}
        library = SHELL / "wallpaper/library.js"
        cases = {
            'Lib.filter(input, {}, null, "", "")': ["moss", "twilight #1", "luna"],
            f'Lib.filter(input, {json.dumps(colors)}, null, "purple", "")': ["twilight #1"],
            'Lib.filter(input, {}, ["/w/pony/luna.jpg", "/gone.jpg", "/w/forest/moss.jpg"], "", "")': ["luna", "moss"],
            'Lib.filter(input, {}, null, "", "PONY tw")': ["twilight #1"],
        }
        for expression, expected in cases.items():
            with self.subTest(expression=expression):
                self.assertEqual(self.probe(library, expression + ".map(i => i.name)", images), expected)
        self.assertEqual(self.probe(library, 'Lib.fileUrl("/w/pony/twilight #1.jpg")', None),
                         "file:///w/pony/twilight%20%231.jpg")
        self.assertEqual(self.probe(library, 'Lib.label(12, "blue", false, "")', None), "Blue · 12")

    def test_color_class_of_pixels(self):
        colors = SHELL / "wallpaper/colors.js"
        def pixels(*rgb, count=4):
            return [v for color in rgb for v in (*color, 255)] * count
        cases = {(40, 110, 210): "blue", (60, 140, 70): "green", (240, 110, 175): "pink",
                 (128, 128, 128): "gray", (130, 70, 200): "purple", (225, 130, 30): "orange"}
        for rgb, expected in cases.items():
            with self.subTest(rgb=rgb):
                self.assertEqual(self.probe(colors, "Lib.dominant(input)", pixels(rgb)), expected)
        # A few vivid pixels win over more dull ones.
        self.assertEqual(self.probe(colors, "Lib.dominant(input)", pixels((40, 110, 210)) + pixels((90, 90, 90), count=5)), "blue")

    def test_color_class_of_quantized_colors(self):
        # ColorQuantizer gives QColors with channels from 0 to 1, one per equal share of the image.
        colors = [{"r": 0.18, "g": 0.43, "b": 0.82}] * 5 + [{"r": 0.9, "g": 0.9, "b": 0.88}] * 3
        self.assertEqual(self.probe(SHELL / "wallpaper/colors.js", "Lib.dominantColors(input)", colors), "blue")
        self.assertEqual(self.probe(SHELL / "wallpaper/colors.js", "Lib.dominantColors(input)", []), "gray")

    def test_selector_left_and_right_arrows_browse(self):
        from PySide6.QtCore import Qt
        from PySide6.QtQuick import QQuickView
        from PySide6.QtTest import QTest
        view = QQuickView()
        view.resize(1920, 1080)
        view.setSource(QUrl.fromLocalFile(str(SHELL / "wallpaper/SelectorContent.qml")))
        self.assertEqual([e.toString() for e in view.errors()], [])
        root = view.rootObject()
        root.setProperty("images", [{"path": f"/none/w{i}.jpg", "name": f"w{i}", "category": ""} for i in range(5)])
        root.setProperty("current", "/none/w2.jpg")
        view.show()
        self.app.processEvents()

        def press(*keys):
            for key in keys:
                QTest.keyClick(view, key)
                self.app.processEvents()
            selected = root.property("selected")
            return (selected.toVariant() if hasattr(selected, "toVariant") else selected)["name"]

        self.assertEqual(press(), "w2")  # opens on the wallpaper in use
        self.assertEqual(press(Qt.Key.Key_Right), "w3")
        self.assertEqual(press(Qt.Key.Key_Left, Qt.Key.Key_Left), "w1")
        # Typing starts a search; the arrows still browse, they do not move the text cursor.
        self.assertEqual(press(Qt.Key.Key_W), "w2")
        self.assertEqual(press(Qt.Key.Key_Right, Qt.Key.Key_Right), "w4")
        self.assertEqual(press(Qt.Key.Key_Left), "w3")
        # Escape leaves the search (back on the wallpaper in use); same keys in the grid.
        self.assertEqual(press(Qt.Key.Key_Escape), "w2")
        self.assertEqual(press(Qt.Key.Key_Right), "w3")
        root.setProperty("grid", True)
        self.app.processEvents()
        self.assertEqual(press(Qt.Key.Key_Right), "w4")
        self.assertEqual(press(Qt.Key.Key_Left, Qt.Key.Key_Left), "w2")
        view.close()

    def test_cheatsheet_rows_merge_and_fold_binds(self):
        # Shaped like `hyprctl binds -j`; key names as written in the config.
        binds = [
            {"has_description": True, "modmask": 64, "submap": "", "key": "RETURN", "description": "Open the terminal"},
            *[{"has_description": True, "modmask": 64, "submap": "", "key": str(i % 10),
               "description": f"Go to workspace {i}"} for i in range(1, 11)],
            *[{"has_description": True, "modmask": 65, "submap": "", "key": str(i % 10),
               "description": f"Send the window to workspace {i}"} for i in range(1, 11)],
            {"has_description": True, "modmask": 64, "submap": "", "key": "SPACE", "description": "Play or pause"},
            {"has_description": True, "modmask": 0, "submap": "", "key": "XF86AudioPlay", "description": "Play or pause"},
            {"has_description": False, "modmask": 64, "submap": "", "key": "X", "description": ""},
            {"has_description": True, "modmask": 64, "submap": "resize", "key": "Left", "description": "Shrink"},
        ]
        self.assertEqual(self.probe(SHELL / "cheatsheet/binds.js", "Lib.rows(input)", binds), [
            {"description": "Open the terminal", "keys": [["SUPER", "Enter"]]},
            {"description": "Go to workspace 1–10", "keys": [["SUPER", "1…0"]]},
            {"description": "Send the window to workspace 1–10", "keys": [["SUPER", "SHIFT", "1…0"]]},
            {"description": "Play or pause", "keys": [["SUPER", "Space"], ["Play"]]},
        ])


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
