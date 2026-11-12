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
    from PySide6.QtCore import QObject, QUrl
    from PySide6.QtGui import QGuiApplication
    from PySide6.QtQml import QQmlComponent, QQmlEngine
except ImportError:
    QGuiApplication = None

SHELL = REPO / "quickshell"
VISUAL = [
    "components/Icon.qml", "components/Label.qml", "components/Pill.qml",
    "components/RingProgress.qml", "components/NotchCorner.qml",
    "bar/BarContent.qml", "bar/DistroButton.qml", "bar/Workspaces.qml", "bar/MediaChip.qml", "bar/ClockChip.qml",
    "bar/StatusArea.qml", "osd/OsdContent.qml",
    "notifications/NotificationCard.qml", "launcher/LauncherContent.qml", "launcher/LauncherItem.qml",
    "components/SearchField.qml", "clipboard/ClipboardContent.qml",
    "cheatsheet/CheatsheetContent.qml", "cheatsheet/KeyRow.qml",
    "wallpaper/SelectorContent.qml", "wallpaper/SelectorToolbar.qml", "wallpaper/Carousel.qml",
    "wallpaper/SlantedCard.qml", "wallpaper/Backdrop.qml",
    "components/IconButton.qml", "components/Switch.qml", "network/NetworkContent.qml", "components/QuickTile.qml",
    "network/WifiPage.qml", "network/WifiItem.qml", "network/BluetoothPage.qml", "network/DeviceItem.qml",
    "components/Slider.qml", "volume/VolumeContent.qml", "volume/LevelRow.qml", "volume/ChoiceRow.qml",
    "calendar/CalendarContent.qml", "music/MusicContent.qml", "music/Vinyl.qml", "music/LyricsView.qml",
    "power/PowerContent.qml", "system/SystemContent.qml",
    "settings/SettingsContent.qml", "settings/SettingsNav.qml", "settings/AppearancePage.qml",
    "settings/SystemPage.qml", "settings/LivePreview.qml", "settings/ThemeGrid.qml", "settings/Chips.qml",
    "settings/SettingRow.qml", "settings/TextButton.qml", "settings/DisplayPage.qml",
    "settings/WidgetsPage.qml", "settings/ApplyBar.qml",
    "widgets/WidgetsContent.qml", "widgets/WidgetCard.qml", "widgets/ClockPill.qml", "widgets/ResourceCard.qml",
    "widgets/SpectrumCard.qml", "widgets/MediaCard.qml", "lock/LockContent.qml", "widgets/OrganicShape.qml", "dock/DockContent.qml", "overview/OverviewContent.qml", "widgets/CalendarCard.qml", "widgets/WidgetBlock.qml", "widgets/WidgetsDesktop.qml", "settings/DockPage.qml", "settings/HomePage.qml", "settings/WelcomeBanner.qml", "settings/Moon.qml", "settings/TweaksPage.qml",
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
            modes = ["bar", "bar-positions", "overview", "widgets-edit", "bluetooth", "calendar", "cheatsheet", "clipboard", "desktop", "launcher", "lock", "music",
                     "power", "settings", "settings-display", "settings-home", "settings-dock", "settings-system", "settings-tweaks",
                     "settings-widgets", "system", "volume", "wallpaper", "widgets", "wifi"]
            self.assertEqual(sorted(p.name for p in Path(out).iterdir()), sorted(f"forest-moonlit-{m}.png" for m in modes))

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
        images = [{"path": f"/w/{c}/{n}.jpg", "name": n, "category": c, "theme": t}
                  for c, n, t in (("other", "moss", "Fluttershy"), ("pony", "twilight #1", ""), ("pony", "luna", "Luna"))]
        colors = {"/w/other/moss.jpg": "green", "/w/pony/twilight #1.jpg": "purple", "/w/pony/luna.jpg": "blue"}
        library = SHELL / "wallpaper/library.js"
        cases = {
            'Lib.filter(input, {}, null, "", "")': ["moss", "twilight #1", "luna"],
            f'Lib.filter(input, {json.dumps(colors)}, null, "purple", "")': ["twilight #1"],
            'Lib.filter(input, {}, ["/w/pony/luna.jpg", "/gone.jpg", "/w/other/moss.jpg"], "", "")': ["luna", "moss"],
            'Lib.filter(input, {}, null, "", "PONY tw")': ["twilight #1"],
            'Lib.filter(input, {}, null, "", "flutter")': ["moss"],
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
        # The same colors for `tfem wallpapers set --colors`.
        self.assertEqual(self.probe(SHELL / "wallpaper/colors.js", "Lib.palette(input)", colors[4:6]),
                         "#2e6ed1,#e6e6e0")

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

    def test_network_panel_icons_order_and_status_lines(self):
        kinds = SHELL / "network/kinds.js"
        self.assertEqual(self.probe(kinds, "[0.9, 0.6, 0.3, 0.1].map(Lib.wifiIcon)", None),
                         ["wifi", "network_wifi_3_bar", "network_wifi_2_bar", "network_wifi_1_bar"])
        self.assertEqual(self.probe(kinds, '["audio-headset", "input-mouse", "input-gaming", "phone", "", "printer"]'
                                           ".map(Lib.deviceIcon)", None),
                         ["headphones", "mouse", "sports_esports", "smartphone", "bluetooth", "bluetooth"])
        networks = [{"name": "b", "strength": 0.9, "known": False, "connected": False},
                    {"name": "a", "strength": 0.2, "known": True, "connected": False},
                    {"name": "c", "strength": 0.1, "known": True, "connected": True}]
        self.assertEqual(self.probe(kinds, "Lib.sortNetworks(input).map(n => n.name)", networks), ["c", "a", "b"])
        lines = {
            '{ connected: true, secured: true }': "Connected · secured",
            '{ failed: "wrong" }': "Wrong password?",
            '{ known: true }': "Saved",
            '{ secured: false }': "Open network",
            '{ busy: true }': "Connecting…",
        }
        for network, text in lines.items():
            with self.subTest(network=network):
                self.assertEqual(self.probe(kinds, f"Lib.networkStatus({network})", None), text)
        self.assertEqual(self.probe(kinds, "Lib.deviceStatus({ paired: true, connected: true, battery: 0.8 })", None),
                         "Connected · battery 80%")
        self.assertEqual(self.probe(kinds, "Lib.deviceStatus({ paired: false, busy: true })", None), "Pairing…")

    def test_volume_icons_and_labels(self):
        sound = SHELL / "volume/sound.js"
        self.assertEqual(self.probe(sound, "[[0.8, false], [0.3, false], [0, false], [0.8, true]]"
                                           ".map(v => Lib.volumeIcon(v[0], v[1]))", None),
                         ["volume_up", "volume_down", "volume_off", "volume_off"])
        names = '["HDMI / DisplayPort", "Pinkie\'s Headphones", "bluez_output.AA_BB", "Speakers", "Mic"]'
        self.assertEqual(self.probe(sound, f"{names}.map(n => Lib.deviceIcon(n, n === 'Mic'))", None),
                         ["tv", "headphones", "headphones", "speaker", "mic"])
        self.assertEqual(self.probe(sound, "Lib.percent(0.644)", None), "64%")

    def test_lyrics_names_are_cleaned_for_any_player(self):
        lyrics = SHELL / "music/lyrics.js"
        cases = [
            (("Bohemian Rhapsody (Remastered 2011)", "Queen"), {"title": "Bohemian Rhapsody", "artist": "Queen"}),
            (("Daft Punk - Get Lucky (Official Video) ft. Pharrell Williams", "Daft Punk"),
             {"title": "Get Lucky", "artist": "Daft Punk"}),
            (("Blinding Lights [Official Audio]", "The Weeknd - Topic"), {"title": "Blinding Lights", "artist": "The Weeknd"}),
            (("Adele - Hello", ""), {"title": "Hello", "artist": "Adele"}),
            (("Stay (with Justin Bieber)", "The Kid LAROI, Justin Bieber"), {"title": "Stay", "artist": "The Kid LAROI"}),
            (("Clocks - Remastered 2008", "Coldplay"), {"title": "Clocks", "artist": "Coldplay"}),
            (("Hey Jude", "The Beatles"), {"title": "Hey Jude", "artist": "The Beatles"}),
        ]
        for (title, artist), expected in cases:
            with self.subTest(title=title):
                self.assertEqual(self.probe(lyrics, f"Lib.clean({json.dumps(title)}, {json.dumps(artist)})", None), expected)

    def test_lyrics_requests_go_from_exact_to_searches(self):
        lyrics = SHELL / "music/lyrics.js"
        urls = self.probe(lyrics, 'Lib.attempts("Clocks - Remastered 2008", "Coldplay", "A Rush of Blood", 307.9)'
                                  '.map(a => (a.search ? "S " : "G ") + a.url)', None)
        self.assertEqual(urls, [
            "G https://lrclib.net/api/get?track_name=Clocks&artist_name=Coldplay&album_name=A%20Rush%20of%20Blood&duration=308",
            "G https://lrclib.net/api/get?track_name=Clocks&artist_name=Coldplay&duration=308",
            "S https://lrclib.net/api/search?track_name=Clocks&artist_name=Coldplay",
            "S https://lrclib.net/api/search?q=Coldplay%20Clocks"])
        # No artist (a radio, a video): only the free search.
        self.assertEqual(self.probe(lyrics, 'Lib.attempts("Some Song", "", "", 0).length', None), 1)

    def test_lyrics_search_keeps_the_best_record(self):
        lyrics = SHELL / "music/lyrics.js"
        records = [{"id": 1, "duration": 300, "plainLyrics": "a"},
                   {"id": 2, "duration": 260, "syncedLyrics": "[00:01.00] a"},     # 48 s off: dropped
                   {"id": 3, "duration": 311, "syncedLyrics": "[00:01.00] a"},
                   {"id": 4, "duration": 308}]                                    # no lyrics
        self.assertEqual(self.probe(lyrics, "Lib.best(input, 308).id", records), 3)
        self.assertEqual(self.probe(lyrics, "Lib.best(input, 0).id", records), 2)   # length unknown: synced first
        self.assertIsNone(self.probe(lyrics, "Lib.best(input, 308)", []))
        # Every version far from the song's length: the words, without timing.
        far = self.probe(lyrics, "Lib.fromAnswer(Lib.best(input, 400))", records[1:3])
        self.assertEqual((far["kind"], [line["text"] for line in far["lines"]]), ("plain", ["a"]))

    def test_lyrics_times_and_lines(self):
        lyrics = SHELL / "music/lyrics.js"
        self.assertEqual(self.probe(lyrics, "[0, 9.9, 65, 185.4, 3600].map(Lib.clock)", None),
                         ["0:00", "0:09", "1:05", "3:05", "60:00"])
        self.assertEqual(self.probe(lyrics, 'Lib.url("Night Forest", "Pixel Dreams", "", 158.6)', None),
                         "https://lrclib.net/api/get?track_name=Night%20Forest"
                         "&artist_name=Pixel%20Dreams&duration=159")
        answer = {"syncedLyrics": "[00:17.12] Winter wrap up\n[00:05.00] Intro\n[01:02.5] Spring is here\n[01:10.00] ",
                  "plainLyrics": "x"}
        lines = self.probe(lyrics, "Lib.fromAnswer(input)", answer)
        self.assertEqual(lines["kind"], "synced")
        self.assertEqual([(round(l["time"], 2), l["text"]) for l in lines["lines"]],
                         [(5.0, "Intro"), (17.12, "Winter wrap up"), (62.5, "Spring is here"), (70.0, "")])
        self.assertEqual(self.probe(lyrics, "[2, 5, 20, 63, 999].map(p => Lib.current(input.lines, p))", lines),
                         [-1, 0, 1, 2, 3])
        self.assertEqual(self.probe(lyrics, "Lib.fromAnswer(input).kind", {"instrumental": True}), "instrumental")
        self.assertEqual(self.probe(lyrics, "Lib.fromAnswer(input).kind", {"plainLyrics": "a\nb"}), "plain")
        self.assertEqual(self.probe(lyrics, "Lib.fromAnswer(null).kind", None), "none")

    def test_the_distro_logo_comes_from_os_release(self):
        logos = SHELL / "components/logos.js"
        release = 'NAME="Arch Linux"\nPRETTY_NAME="Arch Linux"\nID=arch\nBUILD_ID=rolling\n'
        self.assertEqual(self.probe(logos, "Lib.distroId(input)", release), "arch")
        self.assertEqual(self.probe(logos, "Lib.distroId(input)", 'ID="fedora"\nVERSION_ID=43\n'), "fedora")
        # A derivative is not Arch: ID_LIKE alone gives no logo (Arch's trademark policy).
        self.assertEqual(self.probe(logos, "Lib.distroId(input)", "ID=cachyos\nID_LIKE=arch\n"), "cachyos")
        self.assertEqual(self.probe(logos, '[Lib.has("arch"), Lib.has("cachyos"), Lib.has("")]', None),
                         [True, False, False])
        self.assertIn("fill%3D'%23d19fe4'", self.probe(logos, 'Lib.source("arch", "#d19fe4")', None))

    def test_widget_places_are_parts_of_the_free_space(self):
        lib = SHELL / "widgets/places.js"
        self.assertEqual(self.probe(lib, "Lib.fraction(0, 0, 360, 200, 1920, 1080)", None), [0, 0])
        self.assertEqual(self.probe(lib, "Lib.fraction(1560, 880, 360, 200, 1920, 1080)", None), [1, 1])
        self.assertEqual(self.probe(lib, "Lib.fraction(780, 440, 360, 200, 1920, 1080)", None), [0.5, 0.5])
        self.assertEqual(self.probe(lib, "Lib.fraction(-50, 5000, 360, 200, 1920, 1080)", None), [0, 1])
        self.assertEqual(self.probe(lib, "Lib.text([0.25, 0.6])", None), "0.25,0.6")

    def test_overview_places_windows_in_their_workspace(self):
        lib = SHELL / "overview/overview.js"
        screens = [{"id": 1, "monitor": {"x": 1920, "y": 0, "width": 3840, "height": 2160, "scale": 2}},
                   {"id": 3, "monitor": None}]
        windows = [{"address": "0xa", "workspace": 1, "at": [2400, 540], "size": [960, 540], "floating": True},
                   {"address": "0xb", "workspace": 1, "at": [1920, 0], "size": [480, 1080], "focused": True},
                   {"address": "0xc", "workspace": 12, "at": [0, 0], "size": [10, 10]}]
        model = self.probe(lib, "Lib.model(input.s, input.w, 1)", {"s": screens, "w": windows})
        self.assertEqual([w["id"] for w in model], list(range(1, 11)))
        first = model[0]
        self.assertTrue(first["focused"])
        # Tiled first, floating on top; places in parts of the (scaled) screen.
        self.assertEqual([(w["address"], w["x"], w["y"], w["w"], w["h"]) for w in first["windows"]],
                         [("0xb", 0, 0, 0.25, 1), ("0xa", 0.25, 0.5, 0.5, 0.5)])
        self.assertEqual(model[2]["windows"], [])
        self.assertEqual(self.probe(lib, 'Lib.moveCommand("55d8", 4)', None),
                         'hl.dsp.window.move({ window = "address:0x55d8", workspace = 4, follow = false })')
        self.assertEqual(self.probe(lib, 'Lib.focusCommand("0x55d8")', None),
                         'hl.dsp.focus({ window = "address:0x55d8" })')
        self.assertEqual(self.probe(lib, '["1", "9", "0", "a", ""].map(Lib.workspaceForKey)', None), [1, 9, 10, 0, 0])

    def test_dock_lists_pinned_apps_then_running_ones(self):
        lib = SHELL / "dock/dock.js"
        windows = [{"appId": "kitty", "activated": False}, {"appId": "kitty", "activated": True},
                   {"appId": "org.gnome.Nautilus", "activated": False}, {"appId": "steam", "activated": False},
                   {"appId": "", "activated": False}]
        items = self.probe(lib, 'Lib.items("firefox, kitty,nautilus.desktop", input)', windows)
        self.assertEqual([(i["id"], i["pinned"], i["running"], i["focused"]) for i in items], [
            ("firefox", True, 0, False), ("kitty", True, 2, True), ("nautilus.desktop", True, 1, False),
            ("steam", False, 1, False)])
        # Pin and unpin; clicking a running app cycles its windows.
        self.assertEqual(self.probe(lib, 'Lib.togglePin("firefox,kitty", "Kitty")', None), "firefox")
        self.assertEqual(self.probe(lib, 'Lib.togglePin("firefox", "steam")', None), "firefox,steam")
        self.assertEqual(self.probe(lib, 'Lib.nextWindow(input, "kitty")', windows), 0)
        self.assertEqual(self.probe(lib, 'Lib.nextWindow(input, "firefox")', windows), -1)

    def test_organic_shapes_stay_in_their_box(self):
        lib = SHELL / "widgets/shapes.js"
        for kind in ("cookie", "flower", "clover", "circle", "unknown"):
            points = self.probe(lib, f'Lib.outline("{kind}", 200, 100, 90)', None)
            self.assertEqual(len(points), 90)
            self.assertTrue(all(0 <= x <= 200 and 0 <= y <= 100 for x, y in points), kind)
        # A lobe points straight up; the circle is the same everywhere.
        self.assertAlmostEqual(self.probe(lib, 'Lib.radius("flower", -Math.PI / 2)', None), 1)
        self.assertAlmostEqual(self.probe(lib, 'Lib.radius("circle", 1.234)', None), 1)

    def test_welcome_greeting_and_uptime(self):
        lib = SHELL / "settings/settings.js"
        for hour, words in ((6, "Good morning"), (13, "Good afternoon"), (19, "Good evening"), (23, "Good night"),
                            (3, "Good night")):
            self.assertEqual(self.probe(lib, "Lib.greeting(input)", hour), words)
        for seconds, text in ((600, "10 min"), (12300, "3 h 25 min"), (86400 * 2 + 3600 * 4, "2 days 4 h")):
            self.assertEqual(self.probe(lib, "Lib.uptime(input)", seconds), text)
        logos = SHELL / "components/logos.js"
        release = 'NAME="Arch Linux"\nPRETTY_NAME="Arch Linux"\nID=arch\n'
        self.assertEqual(self.probe(logos, "Lib.distroName(input)", release), "Arch Linux")
        self.assertEqual(self.probe(logos, "Lib.distroName(input)", "NAME=Fedora\n"), "Fedora")

    def test_settings_search_and_pending_changes(self):
        lib = SHELL / "settings/settings.js"
        self.assertEqual(self.probe(lib, 'Lib.search("sleep").map(e => e.id)', None), ["modes", "awake", "sleep"])
        self.assertEqual(self.probe(lib, 'Lib.search("WIFI net").map(e => e.id)', None), ["wifi"])
        self.assertEqual(self.probe(lib, 'Lib.search("  ").length', None), 0)
        values = {"shape.radius": 12, "palette.source": "forest-pine"}
        self.assertEqual(self.probe(lib, 'Lib.change(input, {}, "shape.radius", 8)', values), {"shape.radius": 8})
        self.assertEqual(self.probe(lib, 'Lib.change(input, {"shape.radius": 8}, "shape.radius", 12)', values), {})
        self.assertEqual(self.probe(lib, 'Lib.value(input, {"shape.radius": 4}, "shape.radius")', values), 4)
        self.assertEqual(self.probe(lib, 'Lib.pairs({"b.x": true, "a.y": "cat-tabby"})', None),
                         ["a.y=cat-tabby", "b.x=true"])
        self.assertEqual(self.probe(lib, '[0, 5, 60, 120].map(Lib.minutes)', None), ["Never", "5 min", "1 h", "2 h"])
        self.assertEqual(self.probe(lib, 'Lib.steps([0, 10, 15], 11)', None), [0, 10, 11, 15])
        self.assertEqual(self.probe(lib, 'Lib.steps([0, 10], 10)', None), [0, 10])
        self.assertEqual(self.probe(lib, 'Lib.changes({"a": 1}) + "|" + Lib.changes({"a": 1, "b": 2})', None),
                         "1 change|2 changes")
        entry = {"colors": {"accent": "#111111", "blue": "#2222ff"}}
        self.assertEqual(self.probe(lib, '[Lib.accentColor(input, "theme"), Lib.accentColor(input, "blue")]', entry),
                         ["#111111", "#2222ff"])

    def test_a_change_shows_at_once_then_is_confirmed_or_undone(self):
        # The window shows what was asked for before `tfem settings set` ends.
        lib = SHELL / "settings/settings.js"
        values = {"widgets.cpu": True, "idle.lock": 10}
        self.assertEqual(self.probe(lib, 'Lib.overlay(input, {"widgets.cpu": false})', values),
                         {"widgets.cpu": False, "idle.lock": 10})
        # Read back: confirmed keys leave the overlay, the others wait.
        self.assertEqual(self.probe(lib, 'Lib.settle({"widgets.cpu": false, "idle.lock": 10}, input)',
                                    {"widgets.cpu": False, "idle.lock": 15}), {"idle.lock": 15})
        # Not written: the keys go, the saved value shows again.
        self.assertEqual(self.probe(lib, 'Lib.drop(input, ["widgets.cpu"])', {"widgets.cpu": False, "x": 1}),
                         {"x": 1})

    def test_widget_readings(self):
        lib = SHELL / "widgets/resources.js"
        stat = "cpu  100 0 50 800 50 0 0 0 0 0\ncpu0 1 1 1 1\ncpu1 1 1 1 1\nintr 5\n"
        later = "cpu  160 0 70 860 60 0 0 0 0 0\n"
        self.assertEqual(self.probe(lib, "Lib.cpuSample(input)", stat), {"busy": 150, "total": 1000, "cores": 2})
        # 80 busy jiffies out of 150: idle counts iowait too.
        self.assertAlmostEqual(self.probe(lib, f"Lib.cpuUsage(Lib.cpuSample(input), Lib.cpuSample({later!r}))",
                                          stat), 80 / 150)
        meminfo = "MemTotal:       16000000 kB\nMemFree:  100 kB\nMemAvailable:    9800000 kB\n"
        self.assertEqual(self.probe(lib, "Lib.memory(input)", meminfo), {"used": 6348800000, "total": 16384000000})
        df = "Filesystem 1-blocks Used Available Capacity Mounted on\n/dev/x 500 120 360 25% /\n"
        self.assertEqual(self.probe(lib, "Lib.disk(input)", df), {"used": 120, "total": 480})
        self.assertEqual(self.probe(lib, "Lib.disk(input)", "df: nope"), {"used": 0, "total": 0})
        self.assertEqual(self.probe(lib, "Lib.nvidia(input)", "45, 2048, 8192\n"),
                         {"usage": 0.45, "used": 2048 * 1048576, "total": 8192 * 1048576})
        self.assertEqual(self.probe(lib, "[6.2e9, 8e9, 512e9, 2.1e12].map(Lib.size)", None),
                         ["6.2 GB", "8 GB", "512 GB", "2.1 TB"])
        self.assertEqual(self.probe(lib, "[Lib.usage(6.2e9, 16.4e9), Lib.usage(8e8, 16e9)]", None),
                         ["6.2 / 16 GB", "0.8 / 16 GB"])   # one unit: the card stays short
        self.assertEqual(self.probe(lib, 'Lib.spectrum("0;50;100;", 4)', None), [0, 0.5, 1, 0])

    def test_display_choices(self):
        lib = SHELL / "settings/settings.js"
        screen = {"resolutions": [
            {"size": "2560x1440", "rates": [{"label": "165 Hz", "mode": "2560x1440@165.08"},
                                            {"label": "60 Hz", "mode": "2560x1440@59.95"}]},
            {"size": "1920x1080", "rates": [{"label": "60 Hz", "mode": "1920x1080@60.00"}]},
        ]}
        self.assertEqual(self.probe(lib, 'Lib.modeLabel("2560x1440@143.97")', None), "2560 × 1440 at 144 Hz")
        self.assertEqual([c["value"] for c in self.probe(lib, 'Lib.rateChoices(input, "2560x1440")', screen)],
                         ["auto", "2560x1440@165.08", "2560x1440@59.95"])
        # Only the biggest resolutions, plus the one in use.
        self.assertEqual([c["label"] for c in self.probe(lib, 'Lib.sizeChoices(input, "1920x1080", 1)', screen)],
                         ["2560 × 1440", "1920 × 1080"])
        self.assertEqual(self.probe(lib, 'Lib.fastest(input, "2560x1440")', screen), "2560x1440@165.08")
        # Screens on: off in Hyprland, or turned off in the window, do not count.
        screens = [{"name": "DP-1", "on": True}, {"name": "HDMI-A-1", "on": True}, {"name": "eDP-1", "on": False}]
        self.assertEqual(self.probe(lib, 'Lib.screensOn(input, {})', screens), 2)
        self.assertEqual(self.probe(lib, 'Lib.screensOn(input, {"HDMI-A-1": "off"})', screens), 1)
        self.assertEqual(self.probe(lib, 'Lib.screensOn(input, {"eDP-1": "2560x1440@60.00"})', screens), 3)
        self.assertEqual(self.probe(lib, 'Lib.PAGES.map(p => p.id)', None),
                         ["home", "appearance", "system", "display", "widgets", "dock", "tweaks"])

    def test_every_search_result_leads_to_a_row(self):
        # Rows made by a Repeater are visual children only: they are walked
        # in QML, as SettingsContent.scrollTo does.
        component = QQmlComponent(self.engine)
        component.setData(b'import QtQuick\nSettingsContent {\n'
                          b'    function names(item) {\n'
                          b'        let found = [item.objectName];\n'
                          b'        for (const child of item.children) found = found.concat(names(child));\n'
                          b'        return found;\n'
                          b'    }\n'
                          b'    readonly property var shown: names(this)\n}\n',
                          QUrl.fromLocalFile(str(SHELL / "settings/Probe.qml")))
        window = component.create()
        self.assertEqual([e.toString() for e in component.errors()], [])
        shown = window.property("shown")
        shown = shown.toVariant() if hasattr(shown, "toVariant") else shown
        index = self.probe(SHELL / "settings/settings.js", "Lib.INDEX", None)
        for entry in index:
            with self.subTest(row=entry["id"]):
                self.assertIn(entry["id"], shown)

    def test_calendar_grid_and_week_numbers(self):
        cal = SHELL / "calendar/calendar.js"
        today = "new Date(2026, 10, 7, 17, 49)"
        # November 2026 starts on a Sunday: Monday-first grids open on October 26.
        monday = self.probe(cal, f"Lib.monthGrid(2026, 10, 1, {today})", None)
        self.assertEqual(len(monday), 42)
        self.assertEqual([c["day"] for c in monday[:8]], [26, 27, 28, 29, 30, 31, 1, 2])
        self.assertEqual([c["inMonth"] for c in monday[5:7]], [False, True])
        self.assertEqual([i for i, c in enumerate(monday) if c["today"]], [12])
        self.assertEqual([c["weekend"] for c in monday[:7]], [False] * 5 + [True, True])
        sunday = self.probe(cal, f"Lib.monthGrid(2026, 10, 0, {today})", None)
        self.assertEqual(sunday[0]["day"], 1)
        self.assertEqual(self.probe(cal, f"Lib.rowWeeks(Lib.monthGrid(2026, 10, 1, {today}))", None),
                         [44, 45, 46, 47, 48, 49])
        for date, week in (("2026, 10, 7", 45), ("2021, 0, 1", 53), ("2026, 11, 31", 53), ("2027, 0, 4", 1)):
            with self.subTest(date=date):
                self.assertEqual(self.probe(cal, f"Lib.isoWeek(new Date({date}))", None), week)
        self.assertEqual(self.probe(cal, 'Lib.title("novembre", 2026)', None), "Novembre 2026")

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
        files = sorted(str(p) for p in SHELL.rglob("*.qml")) + sorted(str(p) for p in (REPO / "extras/sddm").rglob("*.qml"))
        done = subprocess.run([QMLLINT, *files], capture_output=True, text=True)
        errors = [line for line in (done.stdout + done.stderr).splitlines() if "Error:" in line]
        self.assertEqual(errors, [])


if __name__ == "__main__":
    unittest.main()
