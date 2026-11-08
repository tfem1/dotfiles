"""Renders the shell with sample data, for screenshots and visual checks.

Usage: python tools/preview/render.py [--theme pony-twilight ...] [--wallpaper IMAGE]
                                     [--wallpapers DIR] [--out DIR]
Needs PySide6 (pip install PySide6-Essentials), no Quickshell or Wayland:
the components drawn here are the shell's own QML files, the theme comes from
the same generator as `tfem generate`, only the data is made up.
"""
from __future__ import annotations

import argparse
import json
import os
import shutil
import subprocess
import sys
import tempfile
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "scripts"))

from theming.context import build_context  # noqa: E402
from theming.palette import find_theme, load_palette, resolve_palette  # noqa: E402
from theming.paths import Paths  # noqa: E402
from theming.settings import load_config, load_theme  # noqa: E402
from theming.template import render as render_template  # noqa: E402
from wallpaper_collection import find, load_collection, theme_for  # noqa: E402

MODES = ("desktop", "widgets", "launcher", "clipboard", "cheatsheet", "wallpaper", "wifi", "bluetooth", "volume",
         "calendar", "music", "power", "system", "settings", "settings-system", "settings-display",
         "settings-widgets")
# Hues of the sample landscapes drawn for the wallpaper selector (degrees).
SAMPLE_HUES = (215, 280, 330, 140, 25, 195, 255, 0, 50, 100, 300, 230, 160, 10)
# The theme some samples bring, as a pony wallpaper would.
SAMPLE_THEMES = {215: "Luna", 280: "Twilight", 330: "Pinkie", 140: "Fluttershy", 195: "Rainbow"}
MODIFIERS = {"SHIFT": 1, "CTRL": 4, "ALT": 8, "SUPER": 64}
SAMPLE_BINDS = [("SUPER + RETURN", "Open the terminal"), ("SUPER + D", "Open the launcher"),
                ("SUPER + C", "Open the clipboard history"), ("SUPER + slash", "Show the keybind cheatsheet")]


def theme_json(name: str) -> str:
    """The theme.json the shell would read for this theme (repository defaults)."""
    paths = Paths.from_env(ROOT, {"HOME": "/nonexistent"})
    theme = load_theme(paths)
    theme["palette.source"] = name
    context = build_context(theme, resolve_palette(theme, paths), paths, load_config(paths))
    return render_template((ROOT / "templates/quickshell/theme.json.tpl").read_text(), context)


def binds_json() -> str:
    """The keybinds of hypr/ as `hyprctl binds -j` lists them (read in the fake
    Hyprland API of the tests when Lua is installed, a short sample otherwise)."""
    lua = shutil.which("lua5.4") or shutil.which("lua")
    binds = SAMPLE_BINDS
    if lua:
        done = subprocess.run([lua, str(ROOT / "tests/lua/check_hypr.lua"), str(ROOT / "hypr")],
                              capture_output=True, text=True, check=True)
        calls = [json.loads(line) for line in done.stdout.splitlines()]
        binds = [(c["args"][0], c["args"][2]["description"]) for c in calls if c["call"] == "bind"]
    result = []
    for keys, description in binds:
        names = keys.split(" + ")
        mask = sum(MODIFIERS.get(name, 0) for name in names[:-1])
        result.append({"has_description": True, "modmask": mask, "submap": "", "key": names[-1],
                       "description": description})
    return json.dumps(result)


def settings_json() -> str:
    """What `tfem settings get` gives with the repository defaults."""
    from settings import get
    return json.dumps(get(Paths.from_env(ROOT, {"HOME": "/nonexistent"})), default=str)


def sample_wallpapers(folder: Path) -> list[dict[str, str]]:
    """Flat landscapes (sky, sun, two rows of hills), one per hue: stand-ins
    for real wallpapers, so the preview needs no download."""
    from PySide6.QtCore import QPointF
    from PySide6.QtGui import QColor, QImage, QPainter, QPolygonF

    images = []
    for number, hue in enumerate(SAMPLE_HUES, start=1):
        image = QImage(960, 540, QImage.Format.Format_RGB32)
        image.fill(QColor.fromHsl(hue, 120, 170))
        painter = QPainter(image)
        painter.setRenderHint(QPainter.RenderHint.Antialiasing)
        painter.setPen(QColor(0, 0, 0, 0))
        painter.setBrush(QColor.fromHsl(hue, 90, 235))
        painter.drawEllipse(QPointF(620 + number * 9, 150), 60, 60)
        for depth, lightness in ((0, 110), (1, 70)):
            painter.setBrush(QColor.fromHsl(hue, 110, lightness))
            base = 330 + depth * 90
            peaks = [QPointF(x, base - ((x * (number + 3) + depth * 170) % 180)) for x in range(0, 1001, 125)]
            painter.drawPolygon(QPolygonF([QPointF(0, 540), *peaks, QPointF(960, 540)]))
        painter.end()
        target = folder / f"sample-{number:02}.png"
        image.save(str(target))
        images.append({"path": str(target), "name": target.stem, "category": "samples",
                       "theme": SAMPLE_THEMES.get(hue, "")})
    return images


def wallpaper_list(folder: Path | None, scratch: Path) -> list[dict[str, str]]:
    if folder is None:
        return sample_wallpapers(scratch)
    found = sorted(p for p in folder.rglob("*") if p.suffix.lower() in (".jpg", ".jpeg", ".png", ".webp"))
    collection = load_collection(ROOT / "wallpapers/collection.toml")
    paths = Paths.from_env(ROOT, {"HOME": "/nonexistent"})
    themes = {}
    for p in found:
        name = theme_for(find(p, collection))
        themes[p] = load_palette(find_theme(name, paths)).name if name else ""
    return [{"path": str(p), "name": p.stem, "category": p.parent.name, "theme": themes[p]} for p in found]


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--theme", action="append", default=[], help="theme name (repeatable)")
    parser.add_argument("--wallpaper", type=Path, help="background image")
    parser.add_argument("--wallpapers", type=Path, help="folder shown in the wallpaper selector")
    parser.add_argument("--locale", default="", help="language of the calendar, e.g. fr_FR")
    parser.add_argument("--out", type=Path, default=Path("preview"), help="output folder")
    args = parser.parse_args(argv)
    os.environ.setdefault("QT_QPA_PLATFORM", "offscreen")
    os.environ.setdefault("QT_QUICK_BACKEND", "software")

    from PySide6.QtCore import QUrl
    from PySide6.QtGui import QGuiApplication
    from PySide6.QtQuick import QQuickView

    app = QGuiApplication(sys.argv[:1])
    args.out.mkdir(parents=True, exist_ok=True)
    wallpaper = QUrl.fromLocalFile(str(args.wallpaper.resolve())) if args.wallpaper else QUrl()
    binds = binds_json()
    scratch = tempfile.TemporaryDirectory()
    wallpapers = json.dumps(wallpaper_list(args.wallpapers, Path(scratch.name)))
    settings = settings_json()
    for name in args.theme or ["pony-twilight"]:
        for mode in MODES:
            view = QQuickView()
            view.setInitialProperties({"themeJson": theme_json(name), "bindsJson": binds, "wallpaper": wallpaper,
                                       "wallpapersJson": wallpapers, "localeName": args.locale,
                                       "settingsJson": settings, "mode": mode})
            view.setSource(QUrl.fromLocalFile(str(Path(__file__).with_name("Scene.qml"))))
            if view.errors():
                for error in view.errors():
                    print(error.toString(), file=sys.stderr)
                return 1
            view.show()
            deadline = time.time() + 1.5  # lets images and icons finish loading
            while time.time() < deadline:
                app.processEvents()
            image = view.grabWindow()
            target = args.out / f"{name}-{mode}.png"
            image.save(str(target))
            if mode == "desktop":
                image.copy(0, 0, image.width(), 60).save(str(args.out / f"{name}-bar.png"))
            print(target)
            view.close()
    return 0


if __name__ == "__main__":
    sys.exit(main())
