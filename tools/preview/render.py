"""Renders the shell with sample data, for screenshots and visual checks.

Usage: python tools/preview/render.py [--theme pony-twilight ...] [--wallpaper IMAGE] [--out DIR]
Needs PySide6 (pip install PySide6-Essentials), no Quickshell or Wayland:
the components drawn here are the shell's own QML files, the theme comes from
the same generator as `tfem generate`, only the data is made up.
"""
from __future__ import annotations

import argparse
import os
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "scripts"))

from theming.context import build_context  # noqa: E402
from theming.palette import resolve_palette  # noqa: E402
from theming.paths import Paths  # noqa: E402
from theming.settings import load_theme  # noqa: E402
from theming.template import render as render_template  # noqa: E402

MODES = ("desktop", "launcher")


def theme_json(name: str) -> str:
    """The theme.json the shell would read for this theme (repository defaults)."""
    paths = Paths.from_env(ROOT, {"HOME": "/nonexistent"})
    theme = load_theme(paths)
    theme["palette.source"] = name
    context = build_context(theme, resolve_palette(theme, paths), paths, {"shell.name": "desktop"})
    return render_template((ROOT / "templates/quickshell/theme.json.tpl").read_text(), context)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--theme", action="append", default=[], help="theme name (repeatable)")
    parser.add_argument("--wallpaper", type=Path, help="background image")
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
    for name in args.theme or ["pony-twilight"]:
        for mode in MODES:
            view = QQuickView()
            view.setInitialProperties({"themeJson": theme_json(name), "wallpaper": wallpaper, "mode": mode})
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
