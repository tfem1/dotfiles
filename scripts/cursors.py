"""Fossa cursors: download them into ~/.local/share/icons/FossaCursors.

Usage: cursors.py fetch [--icons DIR]
Fossa Cursors by adhe (CC BY-SA 4.0, https://www.pling.com/p/1377483/) are
not stored in this repository. Pling gives its download link through its
OCS API, made for the machine asking: the link is read there, the archive
checked against the md5 Pling publishes, then unpacked. The cursor theme
folder (the one holding `cursors/`) is installed as FossaCursors, replacing
an older copy. Safe to run again.
"""
from __future__ import annotations

import argparse
import hashlib
import os
import re
import shutil
import sys
import tarfile
import tempfile
import urllib.request
from pathlib import Path

API = os.environ.get("TFEM_FOSSA_API", "https://api.pling.com/ocs/v1/content/data/1377483")
NAME = "FossaCursors"
USER_AGENT = "dotfiles-cursor-fetch/1.0"


def read(url: str) -> bytes:
    request = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    with urllib.request.urlopen(request, timeout=60) as response:
        return response.read()


def link_and_md5(xml: str) -> tuple[str, str]:
    link = re.search(r"<downloadlink1>([^<]+)</downloadlink1>", xml)
    md5 = re.search(r"<downloadmd5sum1>([0-9a-f]{32})</downloadmd5sum1>", xml)
    if not link or not md5:
        raise ValueError("Pling's answer has no download link")
    return link.group(1).replace("&amp;", "&"), md5.group(1)


def install(archive: bytes, icons: Path) -> Path:
    with tempfile.TemporaryDirectory() as folder:
        work = Path(folder)
        (work / "a.tar.gz").write_bytes(archive)
        with tarfile.open(work / "a.tar.gz") as tar:
            tar.extractall(work / "out", filter="data")   # no paths out of the folder, no links out
        found = sorted(p.parent for p in (work / "out").rglob("cursors") if p.is_dir())
        if not found:
            raise ValueError("no cursor theme (a cursors/ folder) in the archive")
        target = icons / NAME
        icons.mkdir(parents=True, exist_ok=True)
        staged = icons / f".{NAME}.new"
        shutil.rmtree(staged, ignore_errors=True)
        shutil.copytree(found[0], staged, symlinks=True)
        index = staged / "index.theme"
        if not index.exists():
            index.write_text(f"[Icon Theme]\nName={NAME}\nComment=Fossa cursors by adhe (CC BY-SA)\n")
        shutil.rmtree(target, ignore_errors=True)
        staged.rename(target)
        return target


def fetch(icons: Path) -> int:
    link, md5 = link_and_md5(read(API).decode())
    archive = read(link)
    if hashlib.md5(archive).hexdigest() != md5:
        raise ValueError("the downloaded archive does not match Pling's md5")
    print(f"Fossa cursors -> {install(archive, icons)}")
    return 0


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="cursors", description="Download the Fossa cursors.")
    commands = parser.add_subparsers(dest="command", required=True)
    fetch_cmd = commands.add_parser("fetch", help="download the Fossa cursors")
    data = Path(os.environ.get("XDG_DATA_HOME") or Path.home() / ".local/share")
    fetch_cmd.add_argument("--icons", type=Path, default=data / "icons", help="target folder")
    args = parser.parse_args(argv)
    try:
        return fetch(args.icons)
    except (OSError, ValueError, tarfile.TarError) as error:
        print(f"error: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
