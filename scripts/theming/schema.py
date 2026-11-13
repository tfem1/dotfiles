"""Settings schema: type and bounds of every key in theme.toml and config.json.

Default values are not here: they live in theme.toml and config.json at the
root of the repository (a test checks that both agree).
"""
from __future__ import annotations

import difflib
import re
from dataclasses import dataclass
from typing import Mapping

from .colors import Color
from .display import MODE, OFF, OUTPUT
from .icons import FOLDER_COLORS
from .keys import load as load_keys, parse as parse_key

HUES = ("red", "orange", "yellow", "green", "cyan", "blue", "purple", "brown")
# The theme's three colors first: modules set to them keep a theme minimal.
MODULE_COLORS = ("accent", "accent2", "accent3", *HUES)
MODULES = (
    "workspaces", "clock", "media", "resources", "battery", "wifi",
    "network", "bluetooth", "audio", "brightness", "notifications",
)
BASE16_KEYS = tuple(f"base0{digit}" for digit in "0123456789ABCDEF")
_NAME = re.compile(r"[a-z0-9][a-z0-9_-]*")
# A widget moved on the desktop: "x,y" in parts of the screen.
PLACE = re.compile(r"(0(\.\d{1,4})?|1(\.0{1,4})?),(0(\.\d{1,4})?|1(\.0{1,4})?)")
WIDGETS = ("clock", "resources", "audio", "media", "calendar")


@dataclass(frozen=True)
class Field:
    kind: str  # bool | int | float | text | path | name | choice | hue | color | mode | place
    low: float = 0
    high: float = 0
    choices: tuple[str, ...] = ()

    def check(self, value: object) -> str | None:
        """Return an error message, or None when the value is valid."""
        if self.kind == "bool":
            return None if isinstance(value, bool) else "expected true or false"
        if self.kind in ("int", "float"):
            return self._check_number(value)
        if self.kind in ("choice", "hue"):
            return None if value in self.choices else f"must be one of: {', '.join(self.choices)}"
        if not isinstance(value, str):
            return "expected a string"
        if any(ord(char) < 32 for char in value):
            return "control characters are not allowed"
        if self.kind == "text" and not value.strip():
            return "must not be empty"
        if self.kind == "name" and not _NAME.fullmatch(value):
            return "use lowercase letters, digits, '-' or '_' only"
        if self.kind == "mode" and value != OFF and not MODE.fullmatch(value):
            return "expected a screen mode like 2560x1440@165.00, or off"
        if self.kind == "place" and value != "auto" and not PLACE.fullmatch(value):
            return 'expected "auto" or a place like "0.25,0.6" (parts of the screen, 0 to 1)'
        if self.kind == "key":
            try:
                parse_key(value)
            except ValueError as error:
                return str(error)
        if self.kind == "color":
            try:
                Color.parse(value)
            except ValueError as error:
                return str(error)
        return None

    def _check_number(self, value: object) -> str | None:
        allowed = (int,) if self.kind == "int" else (int, float)
        if isinstance(value, bool) or not isinstance(value, allowed):
            return "expected an integer" if self.kind == "int" else "expected a number"
        if not self.low <= value <= self.high:
            return f"must be between {self.low:g} and {self.high:g}"
        return None


def _int(low: int, high: int) -> Field:
    return Field("int", low, high)


def _float(low: float, high: float) -> Field:
    return Field("float", low, high)


BOOL, TEXT, PATH, NAME, COLOR = (Field(kind) for kind in ("bool", "text", "path", "name", "color"))

THEME_SCHEMA: dict[str, Field] = {
    "palette.source": NAME,
    "palette.accent": Field("choice", choices=("theme", *HUES)),
    "palette.mode": Field("choice", choices=("dark", "light")),
    # "few": a theme shows 5 colors (background, text and its three own);
    # "all": also its red, orange, yellow, green, cyan, blue, purple, brown.
    "palette.colors": Field("choice", choices=("few", "all")),
    "wallpaper.path": PATH,
    "wallpaper.follow": BOOL,
    "font.sans": TEXT,
    "font.mono": TEXT,
    "font.size": _int(6, 32),
    "font.mono_size": _int(6, 32),
    "shape.radius": _int(0, 32),
    "shape.border": _int(0, 8),
    "shape.gaps_in": _int(0, 64),
    "shape.gaps_out": _int(0, 128),
    "effects.opacity": _float(0.5, 1.0),
    "effects.blur": BOOL,
    "effects.blur_size": _int(1, 20),
    "effects.blur_passes": _int(1, 4),
    # Settings → Glass: how colorful and grainy the blur is, menus blurred too,
    # and a touch of the accent color in the glass of the shell.
    "effects.blur_vibrancy": _float(0.0, 1.0),
    "effects.blur_noise": _float(0.0, 0.2),
    "effects.blur_popups": BOOL,
    "effects.glass_tint": _float(0.0, 0.3),
    "effects.shadow": BOOL,
    "effects.animations": BOOL,
    "effects.game_mode": BOOL,
    "effects.power_saver": BOOL,
    "cursor.theme": TEXT,
    "cursor.size": _int(8, 96),
    "icons.theme": TEXT,
    "icons.folders": Field("choice", choices=("theme", *FOLDER_COLORS)),
    **{f"modules.{name}": Field("hue", choices=MODULE_COLORS) for name in MODULES},
}

# Tables with optional keys: prefix -> (allowed keys, or a pattern they
# match, type of the values).
OpenTables = Mapping[str, tuple["tuple[str, ...] | re.Pattern[str]", Field]]
THEME_OPEN_TABLES: dict[str, tuple[tuple[str, ...], Field]] = {
    "palette.overrides": (BASE16_KEYS, COLOR),
}

CONFIG_SCHEMA: dict[str, Field] = {
    "shell.name": NAME,
    # Idle steps, in minutes; 0 = never.
    "idle.dim": _int(0, 240),
    "idle.lock": _int(0, 240),
    "idle.screen_off": _int(0, 240),
    "idle.suspend": _int(0, 240),
    # The bar: on which edge of the screen, and with or without its background.
    "bar.position": Field("choice", choices=("top", "bottom", "left", "right")),
    "bar.transparent": BOOL,
    # Its modules in three zones, start|center|end: "workspaces,media|clock|notifications,status".
    "bar.layout": TEXT,
    # The workspaces: dots (the focused one a lit square) or numbered circles.
    "bar.workspaces": Field("choice", choices=("dots", "numbers")),
    # The dock: apps pinned and running, its edge, how see-through, hidden or not.
    "dock.enabled": BOOL,
    "dock.position": Field("choice", choices=("bottom", "left", "right")),
    "dock.opacity": _float(0.2, 1.0),
    "dock.autohide": BOOL,
    "dock.pinned": TEXT,      # desktop file ids, comma separated: "firefox,kitty"
    # Screen recordings (tfem record): the sound they take, if any.
    "record.audio": Field("choice", choices=("none", "computer", "microphone")),
    # Desktop widgets: which ones show, and in which corner of the screen.
    "widgets.corner": Field("choice", choices=("top-left", "top-right", "bottom-left", "bottom-right")),
    **{f"widgets.{name}": BOOL for name in ("clock", "audio", "media", "calendar", "cpu", "gpu", "ram", "disk")},
}

# Keys that were renamed: old key -> (new key, old value -> new value). A
# file that still has the old key keeps working.
CONFIG_RENAMED: dict[str, tuple[str, dict[object, object]]] = {
    "widgets.side": ("widgets.corner", {"left": "top-left", "right": "top-right"}),
}

# Settings → Display: the mode picked for a screen, by port name.
CONFIG_OPEN_TABLES: dict[str, tuple[re.Pattern[str], Field]] = {
    "display.modes": (OUTPUT, Field("mode")),
    # Where each widget was dragged ("auto": back in its corner).
    "widgets.places": (re.compile("|".join(WIDGETS)), Field("place")),
    # Settings → Keybinds: the key chosen for an action of keybinds.toml.
    "keys": (re.compile("|".join(re.escape(action["id"]) for action in load_keys()[0])), Field("key")),
}


def validate(
    values: Mapping[str, object],
    schema: Mapping[str, Field],
    open_tables: OpenTables | None = None,
) -> list[str]:
    """Validate flat settings ("section.key") and return every problem found."""
    open_tables = open_tables or {}
    problems = []
    for key, value in values.items():
        field = schema.get(key) or _open_field(key, open_tables)
        if field is None:
            problems.append(_unknown_key(key, schema, open_tables))
        elif message := field.check(value):
            problems.append(f"{key}: {message}")
    problems += [f"{key}: missing" for key in schema if key not in values]
    return problems


def _open_field(key: str, open_tables: OpenTables) -> Field | None:
    for prefix, (allowed, field) in open_tables.items():
        name = key[len(prefix) + 1:]
        if not key.startswith(prefix + "."):
            continue
        if allowed.fullmatch(name) if isinstance(allowed, re.Pattern) else name in allowed:
            return field
    return None


def _unknown_key(key: str, schema: Mapping[str, Field], open_tables: OpenTables) -> str:
    known = list(schema) + [f"{p}.{k}" for p, (keys, _) in open_tables.items()
                            if not isinstance(keys, re.Pattern) for k in keys]
    close = difflib.get_close_matches(key, known, n=1)
    return f"{key}: unknown key" + (f" (did you mean '{close[0]}'?)" if close else "")
