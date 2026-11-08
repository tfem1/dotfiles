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
from .icons import FOLDER_COLORS

HUES = ("red", "orange", "yellow", "green", "cyan", "blue", "purple", "brown")
# The theme's three colors first: modules set to them keep a theme minimal.
MODULE_COLORS = ("accent", "accent2", "accent3", *HUES)
MODULES = (
    "workspaces", "clock", "media", "resources", "battery", "wifi",
    "network", "bluetooth", "audio", "brightness", "notifications",
)
BASE16_KEYS = tuple(f"base0{digit}" for digit in "0123456789ABCDEF")
_NAME = re.compile(r"[a-z0-9][a-z0-9_-]*")


@dataclass(frozen=True)
class Field:
    kind: str  # bool | int | float | text | path | name | choice | hue | color
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
    "effects.shadow": BOOL,
    "effects.animations": BOOL,
    "cursor.theme": TEXT,
    "cursor.size": _int(8, 96),
    "icons.theme": TEXT,
    "icons.folders": Field("choice", choices=("theme", *FOLDER_COLORS)),
    **{f"modules.{name}": Field("hue", choices=MODULE_COLORS) for name in MODULES},
}

# Tables with optional keys: prefix -> (allowed keys, type of the values).
THEME_OPEN_TABLES: dict[str, tuple[tuple[str, ...], Field]] = {
    "palette.overrides": (BASE16_KEYS, COLOR),
}

CONFIG_SCHEMA: dict[str, Field] = {
    "shell.name": NAME,
}


def validate(
    values: Mapping[str, object],
    schema: Mapping[str, Field],
    open_tables: Mapping[str, tuple[tuple[str, ...], Field]] | None = None,
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


def _open_field(key: str, open_tables: Mapping[str, tuple[tuple[str, ...], Field]]) -> Field | None:
    for prefix, (allowed, field) in open_tables.items():
        if key.startswith(prefix + ".") and key[len(prefix) + 1:] in allowed:
            return field
    return None


def _unknown_key(key: str, schema: Mapping[str, Field], open_tables: Mapping) -> str:
    known = list(schema) + [f"{p}.{k}" for p, (keys, _) in open_tables.items() for k in keys]
    close = difflib.get_close_matches(key, known, n=1)
    return f"{key}: unknown key" + (f" (did you mean '{close[0]}'?)" if close else "")
