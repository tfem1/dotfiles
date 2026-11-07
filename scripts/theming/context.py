"""Template context: settings, palette and derived values, all flat."""
from __future__ import annotations

from pathlib import Path
from typing import Mapping

from .palette import Palette
from .paths import Paths
from .schema import THEME_SCHEMA


def build_context(theme: Mapping[str, object], palette: Palette, paths: Paths,
                  config: Mapping[str, object] | None = None) -> dict[str, object]:
    # Shell settings (config.json) first: their keys ("shell.name") never
    # clash with the appearance keys of theme.toml.
    context: dict[str, object] = dict(config or {})
    context.update(
        {key: value for key, value in theme.items() if not key.startswith("palette.overrides.")}
    )
    context.update(palette.variables())

    # "theme" takes the theme's signature color (or its purple slot);
    # a hue ("blue", "accent") becomes the matching color of the palette.
    choice = str(theme["palette.accent"])
    if choice == "theme":
        context["accent"] = palette.accent or palette.colors["base0E"]
    else:
        context["accent"] = context[choice]
    context["palette.accent"] = context["accent"]
    for key, field in THEME_SCHEMA.items():
        if field.kind == "hue":
            context[key] = context[str(theme[key])]

    context["wallpaper.path"] = _wallpaper_path(str(theme["wallpaper.path"]), paths)
    return context


def _wallpaper_path(value: str, paths: Paths) -> str:
    """Empty stays empty; relative -> inside ~/Pictures/Wallpapers; "~" expanded."""
    if not value:
        return ""
    if value == "~" or value.startswith("~/"):
        return str(paths.home / value[2:])
    path = Path(value)
    return str(path if path.is_absolute() else paths.wallpapers / path)
