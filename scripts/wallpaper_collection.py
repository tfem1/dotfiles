"""The wallpaper collection (wallpapers/collection.toml): the curated list of
wallhaven images, and the theme each one goes with.

A pony wallpaper that shows one character with a theme names it
(`character = "luna"`): picking it switches to `pony-luna`. A forest
wallpaper goes with the forest theme chosen in theme.toml. Any other image
keeps the current theme.
"""
from __future__ import annotations

import re
import tomllib
from dataclasses import dataclass
from pathlib import Path

_ID = re.compile(r"[a-z0-9]{6}")
_NAME = re.compile(r"[a-z][a-z0-9_-]*")
_FILE = re.compile(r"wallhaven-([a-z0-9]{6})")
FOREST = "forest"


@dataclass(frozen=True)
class Wallpaper:
    category: str
    id: str
    ext: str
    character: str = ""   # the pony shown, when it has a theme

    @property
    def file_name(self) -> str:
        return f"wallhaven-{self.id}.{self.ext}"


def load_collection(path: Path) -> list[Wallpaper]:
    """Every wallpaper of the collection; rejects bad entries."""
    with path.open("rb") as handle:
        data = tomllib.load(handle)
    entries = []
    for category, table in data.items():
        if not _NAME.fullmatch(category) or not isinstance(table, dict):
            raise ValueError(f"invalid category '{category}' in {path}")
        for item in table.get("wallpapers", []):
            wallpaper_id, ext = item.get("id", ""), item.get("ext", "")
            character = item.get("character", "")
            if (not _ID.fullmatch(wallpaper_id) or ext not in ("jpg", "png")
                    or not isinstance(character, str) or character and not _NAME.fullmatch(character)):
                raise ValueError(f"invalid wallpaper {item!r} in {path}")
            entries.append(Wallpaper(category, wallpaper_id, ext, character))
    return entries


def find(image: Path, wallpapers: list[Wallpaper]) -> Wallpaper | None:
    """The collection entry of a downloaded image (wallhaven-<id>.<ext>), if any."""
    match = _FILE.fullmatch(image.stem)
    if not match:
        return None
    return next((wallpaper for wallpaper in wallpapers if wallpaper.id == match.group(1)), None)


def theme_for(wallpaper: Wallpaper | None, forest_theme: str) -> str | None:
    """The theme that goes with a wallpaper, or None to keep the current one."""
    if wallpaper is None:
        return None
    if wallpaper.character:
        return f"{wallpaper.category}-{wallpaper.character}"
    if wallpaper.category == FOREST:
        return forest_theme
    return None
