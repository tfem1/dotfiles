"""FairyWren icons: download them, and set the color of their folders.

Usage: icons.py fetch [--icons DIR]
       icons.py folders COLOR [--icons DIR]
`fetch` downloads only the two themes (FairyWren_Dark and FairyWren_Light)
from gitlab.com/FreshDoctor/FairyWren-Icons (GPL-3.0, not stored in this
repository) into ~/.local/share/icons, replacing an older copy, then gives
the folders the color `tfem generate` chose. `folders` points each theme's
places/colours/default link at COLOR, the way FairyWren's own colours.sh
does. Both are safe to run again.
"""
from __future__ import annotations

import argparse
import os
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import Mapping

from theming.paths import Paths  # noqa: E402  (scripts/ is on sys.path)

ROOT = Path(__file__).resolve().parent.parent
URL = os.environ.get("TFEM_FAIRYWREN_URL", "https://gitlab.com/FreshDoctor/FairyWren-Icons.git")
THEMES = ("FairyWren_Dark", "FairyWren_Light")
_COLOR = re.compile(r"[a-z]+")


def set_folders(icons: Path, color: str) -> list[str]:
    """Points places/colours/default at `color` in each installed theme.
    Returns the themes changed; ValueError for a color FairyWren lacks."""
    if not _COLOR.fullmatch(color):
        raise ValueError(f"invalid folder color '{color}'")
    changed = []
    for theme in THEMES:
        colours = icons / theme / "places/colours"
        if not colours.is_dir():
            continue  # not downloaded (yet): nothing to change
        if not (colours / color).is_dir():
            raise ValueError(f"FairyWren has no '{color}' folders (see {colours})")
        link = colours / "default"
        if link.is_symlink() and os.readlink(link) in (color, f"./{color}"):
            continue
        # A new link renamed over the old one: never a moment without folders.
        spare = colours / ".default.new"
        spare.unlink(missing_ok=True)
        spare.symlink_to(f"./{color}")
        spare.replace(link)
        changed.append(theme)
    return changed


def chosen_color(paths: Paths) -> str | None:
    """The color `tfem generate` last wrote (templates/icons/folders.tpl)."""
    record = paths.data_home / "tfem/icon-folders"
    if not record.is_file():
        return None
    lines = [line.strip() for line in record.read_text().splitlines()]
    return next((line for line in lines if line and not line.startswith("#")), None)


def fetch(icons: Path, paths: Paths) -> int:
    """Downloads the two themes (only those folders), then copies them in place."""
    icons.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="fairywren-", dir=icons) as temp:
        clone = Path(temp) / "repo"
        steps = [["git", "clone", "--quiet", "--depth", "1", "--filter=blob:none", "--sparse", URL, str(clone)],
                 ["git", "-C", str(clone), "sparse-checkout", "set", *THEMES]]
        for step in steps:
            done = subprocess.run(step, capture_output=True, text=True)
            if done.returncode != 0:
                print(f"error: could not download FairyWren: {done.stderr.strip()}", file=sys.stderr)
                return 2
        for theme in THEMES:
            if not (clone / theme / "index.theme").is_file():
                print(f"error: {theme} is missing from the download", file=sys.stderr)
                return 2
            target = icons / theme
            if target.is_symlink() or target.is_file():
                target.unlink()
            elif target.exists():
                shutil.rmtree(target)
            # Moved, links kept as links (the folders are links into colours/).
            shutil.move(str(clone / theme), str(target))
    color = chosen_color(paths) or "blue"
    set_folders(icons, color)
    print(f"FairyWren icons installed in {paths.pretty(icons)} (folders: {color})")
    return 0


def main(argv: list[str] | None = None, env: Mapping[str, str] = os.environ) -> int:
    parser = argparse.ArgumentParser(prog="icons", description="FairyWren icons.")
    commands = parser.add_subparsers(dest="command", required=True)
    fetch_cmd = commands.add_parser("fetch", help="download FairyWren (dark and light)")
    folders_cmd = commands.add_parser("folders", help="set the color of the folders")
    folders_cmd.add_argument("color", help="a FairyWren color: blue, pink, violet, green...")
    for command in (fetch_cmd, folders_cmd):
        command.add_argument("--icons", type=Path, help="icon folder (default ~/.local/share/icons)")
    args = parser.parse_args(argv)
    paths = Paths.from_env(ROOT, env)
    icons = args.icons or paths.data_home / "icons"
    try:
        if args.command == "fetch":
            return fetch(icons, paths)
        changed = set_folders(icons, args.color)
        if changed:
            print(f"folders: {args.color} ({', '.join(changed)})")
        return 0
    except (OSError, ValueError) as error:
        print(f"error: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
