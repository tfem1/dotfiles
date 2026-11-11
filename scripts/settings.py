"""Settings, for the Settings window (SUPER + H) and the command line.

Usage: settings.py get                         everything the window shows, as JSON
       settings.py set KEY=VALUE [KEY=VALUE...] change settings, then regenerate
Keys are those of theme.toml (palette.source, shape.radius, effects.blur...)
and config.json (idle.lock...). Values are checked like the files are; your
files keep their comments and other keys. `set --no-generate` only writes.
"""
from __future__ import annotations

import json
import os
import sys
from pathlib import Path
from typing import Mapping

from theming.context import build_context  # noqa: E402  (scripts/ is on sys.path)
from theming.edit import set_value  # noqa: E402
from theming.generate import main as generate  # noqa: E402
from theming.palette import PaletteError, load_palette, resolve_palette, theme_dirs  # noqa: E402
from theming.paths import Paths  # noqa: E402
from theming.icons import MEASURED  # noqa: E402
from theming.schema import CONFIG_RENAMED, CONFIG_SCHEMA, HUES, THEME_OPEN_TABLES, THEME_SCHEMA, Field  # noqa: E402
from theming.settings import SettingsError, load_config, load_theme  # noqa: E402
from theming.writer import write_atomic  # noqa: E402

ROOT = Path(__file__).resolve().parent.parent
# Colors of each theme for the previews, named as in the shell's theme.json.
PREVIEW = {"bg": "bg", "bgAlt": "bg_alt", "surface": "surface", "muted": "muted", "subtle": "subtle",
           "fg": "fg", "fgBright": "fg_bright", "accent": "accent", "accent2": "accent2",
           "accent3": "accent3", **{hue: hue for hue in HUES}}


def themes(paths: Paths, theme: Mapping[str, object], config: Mapping[str, object]) -> list[dict]:
    """Every theme with the colors the shell would take from it (for the
    previews): yours first when one has the name of a bundled one."""
    seen, found = set(), []
    for folder in theme_dirs(paths):
        for path in sorted(folder.glob("*.toml")) if folder.is_dir() else []:
            if path.stem in seen:
                continue
            seen.add(path.stem)
            try:
                palette = load_palette(path)
                context = build_context({**theme, "palette.source": path.stem}, palette, paths, config)
            except (PaletteError, KeyError, ValueError):
                continue  # a broken theme of yours is left out, not fatal
            colors = {name: context[key].hex() for name, key in PREVIEW.items()}
            found.append({"id": path.stem, "name": palette.name, "family": palette.family,
                          "variant": palette.variant, "colors": colors})
    return sorted(found, key=lambda item: (item["family"] not in ("Forest", "Cat"), item["family"], item["name"]))


def get(paths: Paths) -> dict:
    theme, config = load_theme(paths), load_config(paths)
    # The current palette resolved, so the window knows what is in use.
    resolve_palette(theme, paths)
    fields = {key: {"kind": field.kind, "low": field.low, "high": field.high, "choices": list(field.choices)}
              for key, field in {**THEME_SCHEMA, **CONFIG_SCHEMA}.items()}
    return {"values": {**theme, **config}, "fields": fields, "themes": themes(paths, theme, config),
            "folders": MEASURED}


def field_of(key: str) -> tuple[Field, str]:
    """The field of a key and the file it lives in ("theme" or "config")."""
    if key in THEME_SCHEMA:
        return THEME_SCHEMA[key], "theme"
    if key in CONFIG_SCHEMA:
        return CONFIG_SCHEMA[key], "config"
    for prefix, (allowed, field) in THEME_OPEN_TABLES.items():
        if key.startswith(prefix + ".") and key[len(prefix) + 1:] in allowed:
            return field, "theme"
    raise ValueError(f"unknown setting '{key}'")


def parse(key: str, text: str) -> object:
    """The typed value of `text` for `key`, checked like the files."""
    field, _ = field_of(key)
    value: object = text
    if field.kind == "bool":
        if text.lower() not in ("true", "false", "on", "off"):
            raise ValueError(f"{key}: expected true or false")
        value = text.lower() in ("true", "on")
    elif field.kind in ("int", "float"):
        try:
            value = int(text) if field.kind == "int" else float(text)
        except ValueError:
            raise ValueError(f"{key}: expected a number") from None
    if problem := field.check(value):
        raise ValueError(f"{key}: {problem}")
    return value


def set_values(pairs: list[str], paths: Paths) -> list[str]:
    """Writes every KEY=VALUE, all or none. Returns the keys changed."""
    changes = []
    for pair in pairs:
        key, sep, text = pair.partition("=")
        if not sep:
            raise ValueError(f"'{pair}': expected KEY=VALUE")
        changes.append((key.strip(), parse(key.strip(), text)))
    theme_file, config_file = paths.user_dir / "theme.toml", paths.user_dir / "config.json"
    text = theme_file.read_text() if theme_file.exists() else \
        "# Your settings: only the keys written here replace the defaults.\n"
    config = json.loads(config_file.read_text()) if config_file.exists() else {}
    for key, value in changes:
        table, name = key.rsplit(".", 1)
        if field_of(key)[1] == "theme":
            text = set_value(text, table, name, value)
        else:
            config.setdefault(table, {})[name] = value
    for old, (new, _) in CONFIG_RENAMED.items():   # the old name of a key just written goes
        old_table, old_name = old.rsplit(".", 1)
        if any(key == new for key, _ in changes):
            config.get(old_table, {}).pop(old_name, None)
    if any(field_of(key)[1] == "theme" for key, _ in changes):
        write_atomic(theme_file, text)
    if any(field_of(key)[1] == "config" for key, _ in changes):
        write_atomic(config_file, json.dumps(config, indent=2) + "\n")
    return [key for key, _ in changes]


def main(argv: list[str] | None = None, env: Mapping[str, str] = os.environ) -> int:
    args = list(sys.argv[1:] if argv is None else argv)
    paths = Paths.from_env(ROOT, env)
    try:
        if args[:1] == ["get"] and len(args) == 1:
            print(json.dumps(get(paths), ensure_ascii=False, default=str))
            return 0
        if args[:1] == ["set"] and len(args) > 1:
            write_only = "--no-generate" in args
            changed = set_values([a for a in args[1:] if a != "--no-generate"], paths)
            print("changed: " + ", ".join(changed))
            return 0 if write_only else generate(["--root", str(ROOT)], env=env)
    except (OSError, ValueError, SettingsError, PaletteError) as error:
        print(f"error: {error}", file=sys.stderr)
        return 1
    print(__doc__.strip().splitlines()[2], file=sys.stderr)
    return 64


if __name__ == "__main__":
    sys.exit(main())
