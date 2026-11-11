"""Wallpapers: download the collection (wallpapers/collection.toml) from
wallhaven.cc, list the images, and set the wallpaper.

Usage: wallpapers.py fetch [--category NAME] [--dest DIR] [--dry-run]
       wallpapers.py list [--json]
       wallpapers.py set IMAGE [--colors #RRGGBB,...]
Files land in ~/Pictures/Wallpapers/<category>/wallhaven-<id>.<ext>; files
already there are kept, so the command can be run again safely. `set` writes
the wallpaper in your theme.toml and regenerates the files that use it. With
`wallpaper.follow` on, the wallpaper also brings its theme: given the
image's main colors (the shell reads them), a theme made from those colors,
green for a green image, blue for a blue one; without them, the theme a
wallpaper of the collection names. Then every file is regenerated. `fetch` also deletes the old downloads of
wallpapers taken out of the collection.
"""
from __future__ import annotations

import argparse
import json
import os
import sys
import time
import tomllib
import urllib.error
import urllib.request
from pathlib import Path
from typing import Mapping

from theming.colors import Color  # noqa: E402  (scripts/ is on sys.path)
from theming.edit import set_value  # noqa: E402
from theming.from_wallpaper import theme_text  # noqa: E402
from theming.generate import main as generate  # noqa: E402
from theming.palette import WALLPAPER_PALETTE, WALLPAPER_SOURCE, PaletteError, find_theme, load_palette  # noqa: E402
from theming.paths import Paths  # noqa: E402
from theming.settings import SettingsError, load_theme  # noqa: E402
from theming.writer import write_atomic  # noqa: E402
from wallpaper_collection import Wallpaper, find, load_collection, prune, theme_for  # noqa: E402

ROOT = Path(__file__).resolve().parent.parent
IMAGES = {".jpg", ".jpeg", ".png", ".webp"}
BASE_URL = os.environ.get("TFEM_WALLPAPER_BASE", "https://w.wallhaven.cc")
USER_AGENT = "dotfiles-wallpaper-fetch/1.0"
COLLECTION = ROOT / "wallpapers/collection.toml"


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
    removed = prune(args.collection, args.dest, args.dry_run)
    if removed and not args.dry_run:
        print(f"{removed} wallpapers no longer in the collection deleted")
    entries = load_collection(args.collection)
    if args.category:
        entries = [entry for entry in entries if entry.category == args.category]
    done = kept = failed = 0
    for entry in entries:
        target = args.dest / entry.category / entry.file_name
        if target.exists() and target.stat().st_size > 0:
            kept += 1
            continue
        if args.dry_run:
            print(f"would download {url_for(entry.id, entry.ext)} -> {target}")
            continue
        try:
            download(url_for(entry.id, entry.ext), target)
            done += 1
            print(f"  {entry.category}/{target.name}")
        except (urllib.error.URLError, OSError) as error:
            failed += 1
            print(f"  failed: {entry.category}/{target.name} ({error})", file=sys.stderr)
    print(f"{done} downloaded, {kept} already there, {failed} failed -> {args.dest}")
    return 2 if failed else 0


def followed_theme(image: Path, wallpapers: list[Wallpaper], theme: Mapping[str, object],
                   colors: list[Color] | None = None) -> str | None:
    """The theme picking `image` switches to, when `wallpaper.follow` is on:
    with the image's colors (the shell reads them), a theme made from them
    ("wallpaper"), so it always has the colors of the picture; without them,
    the theme a wallpaper of the collection names; None keeps the theme."""
    if not theme["wallpaper.follow"]:
        return None
    return WALLPAPER_SOURCE if colors else theme_for(find(image, wallpapers))


def parse_colors(text: str | None) -> list[Color] | None:
    """"#1c0e36,#3e938a,...": the main colors the shell read in the image."""
    if not text:
        return None
    colors = [Color.parse(part.strip()) for part in text.split(",") if part.strip()]
    if not 1 <= len(colors) <= 64:
        raise ValueError("--colors takes 1 to 64 colors")
    return colors


def theme_title(name: str, paths: Paths, known: dict[str, str]) -> str:
    """The readable name of a theme ("Luna"), "" when it does not exist."""
    if name not in known:
        try:
            known[name] = load_palette(find_theme(name, paths)).name
        except PaletteError:
            known[name] = ""
    return known[name]


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
    try:
        theme, wallpapers = load_theme(paths), load_collection(COLLECTION)
    except SettingsError as error:
        print(f"warning: {error}", file=sys.stderr)
        theme, wallpapers = None, []
    known: dict[str, str] = {}
    for image in found:
        name = followed_theme(Path(image["path"]), wallpapers, theme) if theme else None
        image["theme"] = theme_title(name, paths, known) if name else ""
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
    theme = load_theme(paths)
    try:
        colors = parse_colors(args.colors)
    except ValueError as error:
        print(f"error: {error}", file=sys.stderr)
        return 1
    switch = followed_theme(image, load_collection(COLLECTION), theme, colors)
    if switch == WALLPAPER_SOURCE:
        # A theme made from this image's colors (theming/from_wallpaper.py).
        noir = (ROOT / "themes/noir.toml").read_text()
        write_atomic(paths.state_dir / WALLPAPER_PALETTE, theme_text(colors, image.name, noir))
    elif switch == theme["palette.source"]:
        switch = None
    elif switch and not theme_title(switch, paths, {}):
        print(f"warning: theme '{switch}' not found: the theme is kept", file=sys.stderr)
        switch = None
    settings = paths.user_dir / "theme.toml"
    text = settings.read_text() if settings.exists() else "# Your settings: only the keys written here replace the defaults.\n"
    text = set_value(text, "wallpaper", "path", value)
    if switch:
        text = set_value(text, "palette", "source", switch)
    write_atomic(settings, text)
    shown = "made from the wallpaper's colors" if switch == WALLPAPER_SOURCE else switch
    print(f"wallpaper: {paths.pretty(image)}" + (f"\ntheme: {shown}" if switch else ""))
    # Same theme: only the files that show the wallpaper, no compositor reload.
    only = [] if switch else ["--only", "quickshell,hyprlock,sddm"]
    return generate(["--root", str(ROOT), *only], env=env)


def main(argv: list[str] | None = None, env: Mapping[str, str] = os.environ) -> int:
    parser = argparse.ArgumentParser(prog="wallpapers", description="Download the wallpaper collection.")
    commands = parser.add_subparsers(dest="command", required=True)
    fetch_cmd = commands.add_parser("fetch", help="download the wallpapers that are missing")
    fetch_cmd.add_argument("--category", help="only this category (forest or cats)")
    fetch_cmd.add_argument("--dest", type=Path, default=default_dest(), help="target folder")
    fetch_cmd.add_argument("--dry-run", action="store_true", help="list what would be downloaded")
    fetch_cmd.add_argument("--collection", type=Path, default=COLLECTION,
                           help=argparse.SUPPRESS)
    list_cmd = commands.add_parser("list", help="list the images of the wallpaper folder")
    list_cmd.add_argument("--json", action="store_true", help="as JSON (used by the shell)")
    set_cmd = commands.add_parser("set", help="use an image as wallpaper")
    set_cmd.add_argument("image", help="image path, absolute or inside the wallpaper folder")
    set_cmd.add_argument("--colors", help="the image's main colors (#rrggbb,...), read by the shell: "
                                          "the theme is then made from them")
    args = parser.parse_args(argv)
    paths = Paths.from_env(ROOT, env)
    try:
        if args.command == "list":
            return list_images(args, paths)
        if args.command == "set":
            return set_wallpaper(args, paths, env)
        return fetch(args)
    except (OSError, ValueError, tomllib.TOMLDecodeError, SettingsError) as error:
        print(f"error: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
