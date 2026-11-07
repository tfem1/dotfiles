"""Wallpapers: download the collection (wallpapers/collection.toml) from
wallhaven.cc, list the images, and set the wallpaper.

Usage: wallpapers.py fetch [--category NAME] [--dest DIR] [--dry-run]
       wallpapers.py list [--json]
       wallpapers.py set IMAGE
Files land in ~/Pictures/Wallpapers/<category>/wallhaven-<id>.<ext>; files
already there are kept, so the command can be run again safely. `set` writes
the wallpaper in your theme.toml and regenerates the files that use it.
"""
from __future__ import annotations

import argparse
import json
import os
import re
import sys
import time
import tomllib
import urllib.error
import urllib.request
from pathlib import Path
from typing import Mapping

from theming.edit import set_value  # noqa: E402  (scripts/ is on sys.path)
from theming.generate import main as generate  # noqa: E402
from theming.paths import Paths  # noqa: E402
from theming.writer import write_atomic  # noqa: E402

ROOT = Path(__file__).resolve().parent.parent
IMAGES = {".jpg", ".jpeg", ".png", ".webp"}
BASE_URL = os.environ.get("TFEM_WALLPAPER_BASE", "https://w.wallhaven.cc")
USER_AGENT = "dotfiles-wallpaper-fetch/1.0"
_ID = re.compile(r"[a-z0-9]{6}")
_CATEGORY = re.compile(r"[a-z][a-z0-9_-]*")


def load_collection(path: Path) -> list[tuple[str, str, str]]:
    """Returns (category, id, extension) for every wallpaper; rejects bad entries."""
    with path.open("rb") as handle:
        data = tomllib.load(handle)
    entries = []
    for category, table in data.items():
        if not _CATEGORY.fullmatch(category) or not isinstance(table, dict):
            raise ValueError(f"invalid category '{category}' in {path}")
        for item in table.get("wallpapers", []):
            wallpaper_id, ext = item.get("id", ""), item.get("ext", "")
            if not _ID.fullmatch(wallpaper_id) or ext not in ("jpg", "png"):
                raise ValueError(f"invalid wallpaper {item!r} in {path}")
            entries.append((category, wallpaper_id, ext))
    return entries


def default_dest() -> Path:
    pictures = os.environ.get("XDG_PICTURES_DIR") or str(Path.home() / "Pictures")
    return Path(pictures) / "Wallpapers"


def url_for(wallpaper_id: str, ext: str) -> str:
    return f"{BASE_URL}/full/{wallpaper_id[:2]}/wallhaven-{wallpaper_id}.{ext}"


def download(url: str, target: Path, attempts: int = 3) -> None:
    """Downloads to a temporary file, then renames it: no half-written image."""
    target.parent.mkdir(parents=True, exist_ok=True)
    partial = target.with_name(target.name + ".part")
    request = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    for attempt in range(1, attempts + 1):
        try:
            with urllib.request.urlopen(request, timeout=60) as response, partial.open("wb") as out:
                while chunk := response.read(1 << 16):
                    out.write(chunk)
            partial.replace(target)
            return
        except urllib.error.HTTPError as error:
            # Only rate limits and server errors are worth another try.
            if error.code not in (429, 500, 502, 503, 504) or attempt == attempts:
                raise
        except (urllib.error.URLError, TimeoutError):
            if attempt == attempts:
                raise
        finally:
            partial.unlink(missing_ok=True)
        time.sleep(2 ** attempt)


def fetch(args: argparse.Namespace) -> int:
    entries = load_collection(args.collection)
    if args.category:
        entries = [entry for entry in entries if entry[0] == args.category]
    done = kept = failed = 0
    for category, wallpaper_id, ext in entries:
        target = args.dest / category / f"wallhaven-{wallpaper_id}.{ext}"
        if target.exists() and target.stat().st_size > 0:
            kept += 1
            continue
        if args.dry_run:
            print(f"would download {url_for(wallpaper_id, ext)} -> {target}")
            continue
        try:
            download(url_for(wallpaper_id, ext), target)
            done += 1
            print(f"  {category}/{target.name}")
        except (urllib.error.URLError, OSError) as error:
            failed += 1
            print(f"  failed: {category}/{target.name} ({error})", file=sys.stderr)
    print(f"{done} downloaded, {kept} already there, {failed} failed -> {args.dest}")
    return 2 if failed else 0


def images(folder: Path) -> list[dict[str, str]]:
    """Every image under `folder`, by category (first sub-folder) then name."""
    found = [path for path in folder.rglob("*") if path.suffix.lower() in IMAGES and path.is_file()]
    result = []
    for path in sorted(found, key=lambda p: (p.relative_to(folder).parts[:-1], p.name.lower())):
        parts = path.relative_to(folder).parts
        result.append({"path": str(path), "name": path.stem, "category": parts[0] if len(parts) > 1 else ""})
    return result


def list_images(args: argparse.Namespace, paths: Paths) -> int:
    found = images(paths.wallpapers)
    if args.json:
        print(json.dumps(found, ensure_ascii=False))
    else:
        for image in found:
            print(paths.pretty(Path(image["path"])))
    return 0


def set_wallpaper(args: argparse.Namespace, paths: Paths, env: Mapping[str, str]) -> int:
    image = Path(args.image.replace("~", str(paths.home), 1) if args.image.startswith("~") else args.image)
    if not image.is_absolute():
        image = (paths.wallpapers / image) if (paths.wallpapers / image).exists() else image.resolve()
    if not image.is_file() or image.suffix.lower() not in IMAGES:
        print(f"error: {args.image}: not an image (jpg, png or webp)", file=sys.stderr)
        return 1
    # Inside the wallpaper folder the path is kept relative, as in the defaults.
    try:
        value = str(image.relative_to(paths.wallpapers))
    except ValueError:
        value = str(image)
    settings = paths.user_dir / "theme.toml"
    text = settings.read_text() if settings.exists() else "# Your settings: only the keys written here replace the defaults.\n"
    write_atomic(settings, set_value(text, "wallpaper", "path", value))
    print(f"wallpaper: {paths.pretty(image)}")
    # Only the files that show the wallpaper: no compositor reload needed.
    return generate(["--root", str(ROOT), "--only", "quickshell,hyprlock"], env=env)


def main(argv: list[str] | None = None, env: Mapping[str, str] = os.environ) -> int:
    parser = argparse.ArgumentParser(prog="wallpapers", description="Download the wallpaper collection.")
    commands = parser.add_subparsers(dest="command", required=True)
    fetch_cmd = commands.add_parser("fetch", help="download the wallpapers that are missing")
    fetch_cmd.add_argument("--category", help="only this category (e.g. forest, pony)")
    fetch_cmd.add_argument("--dest", type=Path, default=default_dest(), help="target folder")
    fetch_cmd.add_argument("--dry-run", action="store_true", help="list what would be downloaded")
    fetch_cmd.add_argument("--collection", type=Path, default=ROOT / "wallpapers/collection.toml",
                           help=argparse.SUPPRESS)
    list_cmd = commands.add_parser("list", help="list the images of the wallpaper folder")
    list_cmd.add_argument("--json", action="store_true", help="as JSON (used by the shell)")
    set_cmd = commands.add_parser("set", help="use an image as wallpaper")
    set_cmd.add_argument("image", help="image path, absolute or inside the wallpaper folder")
    args = parser.parse_args(argv)
    paths = Paths.from_env(ROOT, env)
    try:
        if args.command == "list":
            return list_images(args, paths)
        if args.command == "set":
            return set_wallpaper(args, paths, env)
        return fetch(args)
    except (OSError, ValueError, tomllib.TOMLDecodeError) as error:
        print(f"error: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
