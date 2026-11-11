"""The wallpaper collection (wallpapers/collection.toml): the curated list of
wallhaven images, and the theme each one goes with.

A wallpaper can name the theme that goes with it (`theme = "forest-moss"`):
picking it switches to that theme. Any other image keeps the current one. `removed` lists the wallpapers taken out of the
collection, whose old downloads `fetch` deletes.
"""
from __future__ import annotations

import re
import tomllib
from dataclasses import dataclass
from pathlib import Path

_ID = re.compile(r"[a-z0-9]{6}")
_NAME = re.compile(r"[a-z][a-z0-9_-]*")
_FILE = re.compile(r"wallhaven-([a-z0-9]{6})")
REMOVED = "removed"


@dataclass(frozen=True)
class Wallpaper:
    category: str
    id: str
    ext: str
    theme: str = ""       # the theme that goes with it (themes/<theme>.toml)

    @property
    def file_name(self) -> str:
        return f"wallhaven-{self.id}.{self.ext}"


def load_collection(path: Path) -> list[Wallpaper]:
    """Every wallpaper of the collection; rejects bad entries."""
    with path.open("rb") as handle:
        data = tomllib.load(handle)
    entries = []
    for category, table in data.items():
        if category == REMOVED:
            continue
        if not _NAME.fullmatch(category) or not isinstance(table, dict):
            raise ValueError(f"invalid category '{category}' in {path}")
        for item in table.get("wallpapers", []):
            wallpaper_id, ext = item.get("id", ""), item.get("ext", "")
            theme = item.get("theme", "")
            if (not _ID.fullmatch(wallpaper_id) or ext not in ("jpg", "png")
                    or not isinstance(theme, str) or theme and not _NAME.fullmatch(theme)):
                raise ValueError(f"invalid wallpaper {item!r} in {path}")
            entries.append(Wallpaper(category, wallpaper_id, ext, theme))
    return entries


def removed_ids(path: Path) -> list[str]:
    """Ids of the wallpapers taken out of the collection."""
    with path.open("rb") as handle:
        ids = tomllib.load(handle).get(REMOVED, [])
    if not isinstance(ids, list) or not all(isinstance(i, str) and _ID.fullmatch(i) for i in ids):
        raise ValueError(f"invalid '{REMOVED}' list in {path}")
    return ids


def find(image: Path, wallpapers: list[Wallpaper]) -> Wallpaper | None:
    """The collection entry of a downloaded image (wallhaven-<id>.<ext>), if any."""
    match = _FILE.fullmatch(image.stem)
    if not match:
        return None
    return next((wallpaper for wallpaper in wallpapers if wallpaper.id == match.group(1)), None)


def theme_for(wallpaper: Wallpaper | None) -> str | None:
    """The theme that goes with a wallpaper, or None to keep the current one."""
    if wallpaper is None or not wallpaper.theme:
        return None
    return wallpaper.theme


def prune(collection: Path, dest: Path, dry_run: bool) -> int:
    """Deletes the downloads of wallpapers taken out of the collection: only
    files named wallhaven-<removed id>.<ext>, then the folders this left
    empty (never a folder of yours). Returns how many files went."""
    gone = set(removed_ids(collection))
    if not dest.is_dir():
        return 0
    count = 0
    touched: set[Path] = set()
    for path in sorted(dest.glob("*/wallhaven-*")):
        if path.is_file() and path.stem.removeprefix("wallhaven-") in gone:
            count += 1
            touched.add(path.parent)
            if dry_run:
                print(f"would delete {path}")
            else:
                path.unlink()
    for folder in touched:
        if not dry_run and not any(folder.iterdir()):
            folder.rmdir()
    return count
