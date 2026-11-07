"""Template context: settings, palette and derived values, all flat."""
from __future__ import annotations

from pathlib import Path
from typing import Mapping

from .palette import Palette
from .paths import Paths
from .schema import THEME_SCHEMA


def build_context(theme: Mapping[str, object], palette: Palette, paths: Paths) -> dict[str, object]:
    context: dict[str, object] = {
        key: value for key, value in theme.items() if not key.startswith("palette.overrides.")
    }
    context.update(palette.variables())

    # A hue ("blue", "accent") becomes the matching color of the palette.
    context["accent"] = context[str(theme["palette.accent"])]
    for key, field in THEME_SCHEMA.items():
        if field.kind == "hue":
            context[key] = context[str(theme[key])]

    context["wallpaper.path"] = _wallpaper_path(str(theme["wallpaper.path"]), paths)
    return context


def _wallpaper_path(value: str, paths: Paths) -> str:
    """Empty stays empty; relative -> inside the repo's wallpapers/; "~" expanded."""
    if not value:
        return ""
    if value == "~" or value.startswith("~/"):
        return str(paths.home / value[2:])
    path = Path(value)
    return str(path if path.is_absolute() else paths.root / "wallpapers" / path)
