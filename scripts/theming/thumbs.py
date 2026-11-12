"""Small copies of the wallpapers for the shell's selector (SUPER + W).

A 4K wallpaper takes a long time to decode: opening the selector on a dozen
of them froze the screen for a moment. The selector shows these 720 px wide
JPEG copies instead, made once with ffmpeg in ~/.cache/tfem/thumbs and named
after the image's path, size and date, so an edited image gets a new one.
Without ffmpeg nothing is made and the selector reads the images themselves.
"""
from __future__ import annotations

import hashlib
import os
import shutil
import subprocess
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
from typing import Iterable, Mapping

WIDTH = 720


def cache_dir(env: Mapping[str, str]) -> Path:
    base = env.get("XDG_CACHE_HOME") or str(Path(env.get("HOME", "~")).expanduser() / ".cache")
    return Path(base) / "tfem/thumbs"


def thumb_path(image: Path, cache: Path) -> Path:
    stat = image.stat()
    key = f"{image.resolve()}|{stat.st_size}|{int(stat.st_mtime)}"
    return cache / (hashlib.sha1(key.encode()).hexdigest() + ".jpg")


def existing(image: Path, cache: Path) -> str:
    """The thumbnail of `image` if it was made, else ""."""
    try:
        thumb = thumb_path(image, cache)
    except OSError:
        return ""
    return str(thumb) if thumb.is_file() else ""


def _make(image: Path, thumb: Path, ffmpeg: str) -> bool:
    partial = thumb.with_suffix(".part.jpg")
    command = [ffmpeg, "-nostdin", "-loglevel", "error", "-y", "-i", str(image),
               "-vf", f"scale={WIDTH}:-2", "-frames:v", "1", "-q:v", "4", "-update", "1", str(partial)]
    try:
        done = subprocess.run(command, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                              timeout=60).returncode == 0
    except (OSError, subprocess.TimeoutExpired):
        done = False
    if done and partial.is_file():
        partial.replace(thumb)
        return True
    partial.unlink(missing_ok=True)
    return False


def make(images: Iterable[Path], cache: Path, ffmpeg: str | None = None) -> tuple[int, int]:
    """Makes the missing thumbnails and drops the ones of images gone.
    Returns (made, failed); (0, 0) without ffmpeg."""
    ffmpeg = ffmpeg or shutil.which("ffmpeg")
    if not ffmpeg:
        return 0, 0
    cache.mkdir(parents=True, exist_ok=True)
    wanted = {thumb_path(image, cache): image for image in images if image.is_file()}
    for old in cache.glob("*.jpg"):
        if old not in wanted:
            old.unlink(missing_ok=True)
    missing = [(image, thumb) for thumb, image in wanted.items() if not thumb.is_file()]
    with ThreadPoolExecutor(max_workers=max(1, min(4, (os.cpu_count() or 2) // 2))) as pool:
        results = list(pool.map(lambda pair: _make(*pair, ffmpeg), missing))
    return results.count(True), results.count(False)
