"""Download the wallpaper collection (wallpapers/collection.toml) from wallhaven.cc.

Usage: wallpapers.py fetch [--category NAME] [--dest DIR] [--dry-run]
Files land in ~/Pictures/Wallpapers/<category>/wallhaven-<id>.<ext>; files
already there are kept, so the command can be run again safely.
"""
from __future__ import annotations

import argparse
import os
import re
import sys
import time
import tomllib
import urllib.error
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
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


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="wallpapers", description="Download the wallpaper collection.")
    commands = parser.add_subparsers(dest="command", required=True)
    fetch_cmd = commands.add_parser("fetch", help="download the wallpapers that are missing")
    fetch_cmd.add_argument("--category", help="only this category (e.g. forest, pony)")
    fetch_cmd.add_argument("--dest", type=Path, default=default_dest(), help="target folder")
    fetch_cmd.add_argument("--dry-run", action="store_true", help="list what would be downloaded")
    fetch_cmd.add_argument("--collection", type=Path, default=ROOT / "wallpapers/collection.toml",
                           help=argparse.SUPPRESS)
    args = parser.parse_args(argv)
    try:
        return fetch(args)
    except (OSError, ValueError, tomllib.TOMLDecodeError) as error:
        print(f"error: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
