"""Settings loading: repository defaults, then the user file, then validation."""
from __future__ import annotations

import json
import tomllib
from pathlib import Path
from typing import Callable

from .paths import Paths
from .schema import CONFIG_OPEN_TABLES, CONFIG_SCHEMA, THEME_OPEN_TABLES, THEME_SCHEMA, validate

THEME_VERSION = 1
CONFIG_VERSION = 1


class SettingsError(Exception):
    def __init__(self, source: Path, problems: list[str]):
        self.source = source
        self.problems = problems
        super().__init__(f"{source}: " + "; ".join(problems))


def load_theme(paths: Paths) -> dict[str, object]:
    """Flat, validated appearance settings ("shape.radius": 12, ...)."""
    return _load(
        paths.root / "theme.toml", paths.user_dir / "theme.toml",
        _read_toml, THEME_VERSION, THEME_SCHEMA, THEME_OPEN_TABLES,
    )


def load_config(paths: Paths) -> dict[str, object]:
    """Flat, validated shell settings ("shell.name": "desktop", ...)."""
    return _load(
        paths.root / "config.json", paths.user_dir / "config.json",
        _read_json, CONFIG_VERSION, CONFIG_SCHEMA, CONFIG_OPEN_TABLES,
    )


def flatten(data: dict, prefix: str = "") -> dict[str, object]:
    """{"shape": {"radius": 12}} -> {"shape.radius": 12}. Lists stay values."""
    flat: dict[str, object] = {}
    for key, value in data.items():
        dotted = f"{prefix}{key}"
        if isinstance(value, dict):
            flat.update(flatten(value, dotted + "."))
        else:
            flat[dotted] = value
    return flat


def _load(defaults: Path, user: Path, reader: Callable[[Path], dict],
          version: int, schema: dict, open_tables: dict) -> dict[str, object]:
    # Keys from the user file replace the defaults one by one.
    values = flatten(reader(defaults))
    source = defaults
    if user.exists():
        values.update(flatten(reader(user)))
        source = user
    found = values.pop("schema", version)
    if not isinstance(found, int) or isinstance(found, bool) or found > version:
        raise SettingsError(source, [
            f"format version {found} is not supported (this version reads up to {version}); "
            "update the project"
        ])
    problems = validate(values, schema, open_tables)
    if problems:
        raise SettingsError(source, problems)
    return values


def _read_toml(path: Path) -> dict:
    try:
        with path.open("rb") as handle:
            return tomllib.load(handle)
    except (OSError, tomllib.TOMLDecodeError) as error:
        raise SettingsError(path, [f"cannot read {path}: {error}"]) from None


def _read_json(path: Path) -> dict:
    try:
        data = json.loads(path.read_text())
    except (OSError, json.JSONDecodeError) as error:
        raise SettingsError(path, [f"cannot read {path}: {error}"]) from None
    if not isinstance(data, dict):
        raise SettingsError(path, [f"{path} must contain a JSON object"])
    return data
