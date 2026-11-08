"""Template context: settings, palette and derived values, all flat."""
from __future__ import annotations

import shlex
from pathlib import Path
from typing import Mapping

from .accents import companions
from .display import chosen, lua_rules
from .icons import folder_color, theme_name
from .idle import listeners
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
        own = (palette.accent2, palette.accent3)
    else:
        context["accent"] = context[choice]
        own = (None, None)  # the theme's companions go with its own accent only
    context["palette.accent"] = context["accent"]
    second, third = companions(context["accent"], palette.colors["base00"], palette.variant)
    context["accent2"] = own[0] or second
    context["accent3"] = own[1] or third
    for key, field in THEME_SCHEMA.items():
        if field.kind == "hue":
            context[key] = context[str(theme[key])]

    # Game mode: everything that costs frames is off, whatever the settings;
    # a fullscreen game may tear (less input lag) and is scanned out directly.
    game = bool(theme.get("effects.game_mode"))
    if game:
        context.update({"effects.animations": False, "effects.blur": False, "effects.shadow": False})
    context["game.tearing"] = game
    context["game.direct_scanout"] = 1 if game else 0
    context["idle.listeners"] = listeners(context)
    context["display.rules"] = lua_rules(chosen(context))
    context["wallpaper.path"] = _wallpaper_path(str(theme["wallpaper.path"]), paths)
    context.update(_login_screen(str(context["wallpaper.path"]), paths))
    # GTK theme and color scheme that match the palette (adw-gtk3, gsettings values).
    dark = palette.variant == "dark"
    context["gtk.theme"] = "adw-gtk3-dark" if dark else "adw-gtk3"
    context["gtk.color_scheme"] = "prefer-dark" if dark else "default"
    # Icons: FairyWren's dark or light half, folders in the accent's color.
    context["icons.name"] = theme_name(str(theme["icons.theme"]), palette.variant)
    folders = str(theme["icons.folders"])
    context["icons.folders"] = folder_color(context["accent"]) if folders == "theme" else folders
    context["dirs.config"] = str(paths.config_home)
    context["dirs.data"] = str(paths.data_home)
    context["dirs.root"] = str(paths.root)
    return context


def _login_screen(wallpaper: str, paths: Paths) -> dict[str, str]:
    """Where the login screen (SDDM) finds its copy of the wallpaper, and the
    command that copies it there (SDDM cannot read your home folder)."""
    if not wallpaper:
        return {"sddm.background": "", "sddm.copy": "true"}
    target = str(paths.sddm_dir / f"background{Path(wallpaper).suffix.lower()}")
    return {"sddm.background": target, "sddm.copy": shlex.join(["cp", "-f", wallpaper, target])}


def _wallpaper_path(value: str, paths: Paths) -> str:
    """Empty stays empty; relative -> inside ~/Pictures/Wallpapers; "~" expanded."""
    if not value:
        return ""
    if value == "~" or value.startswith("~/"):
        return str(paths.home / value[2:])
    path = Path(value)
    return str(path if path.is_absolute() else paths.wallpapers / path)
