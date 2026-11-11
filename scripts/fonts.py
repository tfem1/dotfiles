"""Fonts: download Monocraft, the pixel font used everywhere by default.

Usage: fonts.py fetch [--fonts DIR]
Downloads Monocraft (github.com/IdreesInc/Monocraft, SIL Open Font License
1.1, not stored in this repository), a pinned release checked against its
SHA-256, into ~/.local/share/fonts/Monocraft with its license, then refreshes
the font cache. Safe to run again: a font already there is kept.
"""
from __future__ import annotations

import argparse
import hashlib
import os
import shutil
import subprocess
import sys
import tempfile
import urllib.request
from pathlib import Path
from typing import Mapping

from theming.paths import Paths  # noqa: E402  (scripts/ is on sys.path)

ROOT = Path(__file__).resolve().parent.parent
VERSION = "v4.2.1"
BASE = os.environ.get("TFEM_MONOCRAFT_URL", f"https://github.com/IdreesInc/Monocraft/releases/download/{VERSION}")
LICENSE_URL = os.environ.get("TFEM_MONOCRAFT_LICENSE_URL",
                             f"https://raw.githubusercontent.com/IdreesInc/Monocraft/{VERSION}/LICENSE")
FILE = "Monocraft.ttc"   # every weight, regular and italic, in one file
SHA256 = os.environ.get("TFEM_MONOCRAFT_SHA256", "0ea1aea12f03d552a469fc017f19ea927b53bf9d21e60a41c5c476c3faf3c7f9")


def download(url: str, target: Path) -> None:
    with urllib.request.urlopen(url, timeout=60) as response, target.open("wb") as out:
        shutil.copyfileobj(response, out)


def fetch(fonts: Path) -> int:
    folder = fonts / "Monocraft"
    if (folder / FILE).is_file():
        print(f"Monocraft already in {folder}")
        return 0
    folder.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="monocraft-", dir=folder) as temp:
        part = Path(temp) / FILE
        try:
            download(f"{BASE}/{FILE}", part)
            download(LICENSE_URL, Path(temp) / "LICENSE")
        except OSError as error:
            print(f"error: could not download Monocraft: {error}", file=sys.stderr)
            return 2
        digest = hashlib.sha256(part.read_bytes()).hexdigest()
        if digest != SHA256:
            print(f"error: Monocraft download does not match its checksum ({digest})", file=sys.stderr)
            return 2
        (Path(temp) / "LICENSE").replace(folder / "LICENSE")
        part.replace(folder / FILE)
    if shutil.which("fc-cache"):
        subprocess.run(["fc-cache", "-f", str(folder)], capture_output=True)
    print(f"Monocraft {VERSION} installed in {folder}")
    return 0


def main(argv: list[str] | None = None, env: Mapping[str, str] = os.environ) -> int:
    parser = argparse.ArgumentParser(prog="tfem fonts", description="Download Monocraft.")
    sub = parser.add_subparsers(dest="command", required=True)
    fetch_cmd = sub.add_parser("fetch", help="download Monocraft into your fonts folder")
    fetch_cmd.add_argument("--fonts", type=Path, help="fonts folder (default: ~/.local/share/fonts)")
    args = parser.parse_args(argv)
    paths = Paths.from_env(ROOT, env)
    return fetch(args.fonts or paths.data_home / "fonts")


if __name__ == "__main__":
    sys.exit(main())
