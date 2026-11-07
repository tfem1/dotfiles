"""Contexte des templates : réglages, palette et valeurs dérivées, tous à plat."""
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

    # Une teinte (« blue », « accent ») devient la couleur correspondante de la palette.
    context["accent"] = context[str(theme["palette.accent"])]
    for key, field in THEME_SCHEMA.items():
        if field.kind == "hue":
            context[key] = context[str(theme[key])]

    context["wallpaper.path"] = _wallpaper_path(str(theme["wallpaper.path"]), paths)
    return context


def _wallpaper_path(value: str, paths: Paths) -> str:
    """Chemin vide conservé ; relatif → dans wallpapers/ du repo ; « ~ » développé."""
    if not value:
        return ""
    if value == "~" or value.startswith("~/"):
        return str(paths.home / value[2:])
    path = Path(value)
    return str(path if path.is_absolute() else paths.root / "wallpapers" / path)
