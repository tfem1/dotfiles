"""Palette active : recherche du fichier de thème, lecture, surcharges, rôles et ANSI."""
from __future__ import annotations

import difflib
import tomllib
from dataclasses import dataclass
from pathlib import Path
from typing import Mapping

from .colors import Color
from .paths import Paths
from .schema import BASE16_KEYS

WALLPAPER_SOURCE = "wallpaper"
WALLPAPER_PALETTE = "wallpaper-palette.toml"

# Rôles lisibles dans les templates → slot base16 (conventions de BASE16.md).
ROLES = {
    "bg": "base00", "bg_alt": "base01", "surface": "base02", "muted": "base03",
    "subtle": "base04", "fg": "base05", "fg_bright": "base06",
    "red": "base08", "orange": "base09", "yellow": "base0A", "green": "base0B",
    "cyan": "base0C", "blue": "base0D", "purple": "base0E", "brown": "base0F",
}

# Couleurs 0 à 15 des terminaux, comme le template officiel tinted-theming/tinted-shell.
ANSI = (
    "base00", "base08", "base0B", "base0A", "base0D", "base0E", "base0C", "base05",
    "base03", "base08", "base0B", "base0A", "base0D", "base0E", "base0C", "base07",
)


class PaletteError(Exception):
    """Thème introuvable ou fichier de thème invalide."""


@dataclass(frozen=True)
class Palette:
    name: str
    family: str
    variant: str
    author: str
    colors: dict[str, Color]

    def variables(self) -> dict[str, object]:
        """Couleurs brutes, rôles et ANSI, prêts pour le contexte des templates."""
        values: dict[str, object] = dict(self.colors)
        values.update({role: self.colors[slot] for role, slot in ROLES.items()})
        values.update({f"ansi{index}": self.colors[slot] for index, slot in enumerate(ANSI)})
        values.update({
            "palette.name": self.name, "palette.family": self.family,
            "palette.variant": self.variant, "palette.author": self.author,
        })
        return values


def theme_dirs(paths: Paths) -> list[Path]:
    """Les thèmes personnels passent avant ceux du repo."""
    return [paths.user_dir / "themes", paths.root / "themes"]


def find_theme(name: str, paths: Paths) -> Path:
    if name == WALLPAPER_SOURCE:
        path = paths.state_dir / WALLPAPER_PALETTE
        if not path.exists():
            raise PaletteError(
                "palette.source is 'wallpaper' but no palette was extracted from a "
                "wallpaper yet; pick a wallpaper first or choose a theme"
            )
        return path
    for folder in theme_dirs(paths):
        if (candidate := folder / f"{name}.toml").exists():
            return candidate
    available = sorted({p.stem for d in theme_dirs(paths) if d.is_dir() for p in d.glob("*.toml")})
    close = difflib.get_close_matches(name, available, n=1)
    hint = f" (did you mean '{close[0]}'?)" if close else ""
    raise PaletteError(f"theme '{name}' not found{hint}")


def load_palette(path: Path) -> Palette:
    try:
        with path.open("rb") as handle:
            data = tomllib.load(handle)
    except (OSError, tomllib.TOMLDecodeError) as error:
        raise PaletteError(f"cannot read theme {path}: {error}") from None
    problems = _check_theme(data)
    if problems:
        raise PaletteError(f"invalid theme {path}: " + "; ".join(problems))
    return Palette(
        name=data["name"],
        family=data.get("family", data["name"]),
        variant=data["variant"],
        author=data.get("author", ""),
        colors={key: Color.parse(data["colors"][key]) for key in BASE16_KEYS},
    )


def resolve_palette(theme: Mapping[str, object], paths: Paths) -> Palette:
    """Charge le thème choisi dans theme.toml puis applique palette.overrides."""
    palette = load_palette(find_theme(str(theme["palette.source"]), paths))
    prefix = "palette.overrides."
    overrides = {k[len(prefix):]: Color.parse(v) for k, v in theme.items() if k.startswith(prefix)}
    return Palette(palette.name, palette.family, palette.variant, palette.author,
                   {**palette.colors, **overrides})


def _check_theme(data: dict) -> list[str]:
    problems = []
    if not isinstance(data.get("name"), str) or not data["name"].strip():
        problems.append("'name' is required")
    if data.get("variant") not in ("dark", "light"):
        problems.append("'variant' must be 'dark' or 'light'")
    colors = data.get("colors")
    if not isinstance(colors, dict):
        return problems + ["a [colors] table is required"]
    problems += [f"colors.{key} is missing" for key in BASE16_KEYS if key not in colors]
    problems += [f"colors.{key} is not a base16 slot" for key in colors if key not in BASE16_KEYS]
    for key in BASE16_KEYS:
        try:
            if key in colors:
                Color.parse(colors[key])
        except ValueError as error:
            problems.append(f"colors.{key}: {error}")
    return problems
