"""Fonts: download the two default fonts.

Usage: fonts.py fetch [--fonts DIR]
Google Sans Flex (github.com/googlefonts/googlesans-flex), the interface
font, and Monocraft (github.com/IdreesInc/Monocraft), the pixel font of the
terminals; both SIL Open Font License 1.1, not stored in this repository.
Each is a pinned release checked against its SHA-256, installed into
~/.local/share/fonts/<name> with its license, then the font cache is
refreshed. Safe to run again: a font already there is kept.
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
import zipfile
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


FLEX_VERSION = "v5.000"
FLEX_URL = os.environ.get("TFEM_FLEX_URL", "https://github.com/googlefonts/googlesans-flex/releases/download/"
                          f"{FLEX_VERSION}/GoogleSansFlex-{FLEX_VERSION}.zip")
FLEX_LICENSE_URL = os.environ.get("TFEM_FLEX_LICENSE_URL",
                                  f"https://raw.githubusercontent.com/googlefonts/googlesans-flex/{FLEX_VERSION}/OFL.txt")
FLEX_SHA256 = os.environ.get("TFEM_FLEX_SHA256", "c20b00878dd801d1bfc06d771732447940c7255bf94cf538ce0102c7fb06fa85")
FLEX_FILE = "GoogleSansFlex.ttf"   # the variable font: every weight and width


def download(url: str, target: Path) -> None:
    with urllib.request.urlopen(url, timeout=60) as response, target.open("wb") as out:
        shutil.copyfileobj(response, out)


def fetch_flex(fonts: Path) -> int:
    folder = fonts / "GoogleSansFlex"
    if (folder / FLEX_FILE).is_file():
        print(f"Google Sans Flex already in {folder}")
        return 0
    folder.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="flex-", dir=folder) as temp:
        archive = Path(temp) / "flex.zip"
        try:
            download(FLEX_URL, archive)
            download(FLEX_LICENSE_URL, Path(temp) / "OFL.txt")
        except OSError as error:
            print(f"error: could not download Google Sans Flex: {error}", file=sys.stderr)
            return 2
        digest = hashlib.sha256(archive.read_bytes()).hexdigest()
        if digest != FLEX_SHA256:
            print(f"error: Google Sans Flex download does not match its checksum ({digest})", file=sys.stderr)
            return 2
        with zipfile.ZipFile(archive) as bundle:
            names = [n for n in bundle.namelist() if n.endswith(".ttf") and "/" not in n.strip("/")]
            if not names:
                print("error: no font in the Google Sans Flex archive", file=sys.stderr)
                return 2
            (Path(temp) / FLEX_FILE).write_bytes(bundle.read(names[0]))
        (Path(temp) / "OFL.txt").replace(folder / "OFL.txt")
        (Path(temp) / FLEX_FILE).replace(folder / FLEX_FILE)
    print(f"Google Sans Flex {FLEX_VERSION} installed in {folder}")
    return 0


def fetch(fonts: Path) -> int:
    code = fetch_flex(fonts)
    return max(code, fetch_monocraft(fonts))


def fetch_monocraft(fonts: Path) -> int:
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
    print(f"Monocraft {VERSION} installed in {folder}")
    if shutil.which("fc-cache"):
        subprocess.run(["fc-cache", "-f", str(fonts)], capture_output=True)
    return 0


def main(argv: list[str] | None = None, env: Mapping[str, str] = os.environ) -> int:
    parser = argparse.ArgumentParser(prog="tfem fonts", description="Download Google Sans Flex and Monocraft.")
    sub = parser.add_subparsers(dest="command", required=True)
    fetch_cmd = sub.add_parser("fetch", help="download the default fonts into your fonts folder")
    fetch_cmd.add_argument("--fonts", type=Path, help="fonts folder (default: ~/.local/share/fonts)")
    args = parser.parse_args(argv)
    paths = Paths.from_env(ROOT, env)
    return fetch(args.fonts or paths.data_home / "fonts")


if __name__ == "__main__":
    sys.exit(main())
