"""A theme made from a wallpaper's colors, for images outside the collection.

The shell reads the image's main colors with Quickshell's ColorQuantizer (8
colors, each an equal share of the image) and passes them to `tfem
wallpapers set`. From them come the seeds of the theme builder (builder.py),
which makes every color readable:
- tint: the commonest color of the dark half of the image (the light half
  for a light image, which gets a light theme);
- accent: the most vivid color that also covers a good part of the image
  and stands out from the background (out of that half if it can, another
  hue), placed on its own hue slot;
- text: the tint's hue, so the text belongs to the picture too.
A gray image (no color at all) gets Noir, the black and white theme.
"""
from __future__ import annotations

import math
from collections import Counter
from typing import Iterable

from .builder import SLOTS, BuildError, build_theme, render
from .colors import Color
from .hues import hue_class
from .icons import oklab

NAME = "Wallpaper"
LIGHT_IMAGE = 0.72     # mean OKLab lightness above which an image is light
GRAY = 0.025           # OKLab chroma under which a color counts as gray
TINTED = 0.012         # a background tint needs at least this much color


def _chroma(color: Color) -> float:
    _, a, b = oklab(color)
    return math.hypot(a, b)


def _hue_gap(one: Color, two: Color) -> float:
    """Angle between two hues, from 0 (same) to 1 (opposite)."""
    _, a1, b1 = oklab(one)
    _, a2, b2 = oklab(two)
    gap = abs(math.atan2(b1, a1) - math.atan2(b2, a2)) % (2 * math.pi)
    return min(gap, 2 * math.pi - gap) / math.pi


def seed(colors: Iterable[Color]) -> dict:
    counts = Counter(color.hex() for color in colors)
    if not counts:
        raise ValueError("no colors")
    shares = {Color.parse(hex_): count / sum(counts.values()) for hex_, count in counts.items()}
    by_lightness = sorted(shares, key=lambda color: oklab(color)[0])
    light = sum(oklab(color)[0] * share for color, share in shares.items()) > LIGHT_IMAGE
    half = by_lightness[len(by_lightness) // 2:] if light else by_lightness[:max(1, len(by_lightness) // 2)]
    # The accent stands out from the background: taken from the other half
    # of the image when it has color there.
    tinted = [color for color in half if _chroma(color) >= TINTED]
    background = max(tinted or half, key=lambda color: shares[color])
    vivid = [color for color in shares if _chroma(color) >= GRAY]
    vivid = [color for color in vivid if color not in half] or vivid
    # Vivid, a good part of the image, and another hue than the background.
    accent = max(vivid, key=lambda color: _chroma(color) * math.sqrt(shares[color])
                 * (0.3 + _hue_gap(color, background))) if vivid else Color.parse("#202020" if light else "#f0f0f0")
    # A black or white background has no hue of its own: the accent lends its.
    tint = background if tinted else accent
    result = {"name": NAME, "variant": "light" if light else "dark", "tint": tint.hex(),
              "text": tint.hex(), "accent": accent.hex()}
    if vivid and (slot := hue_class(accent)) in SLOTS:
        result["slots"] = {slot: accent.hex()}
    return result


def theme_text(colors: Iterable[Color], source: str, noir: str) -> str:
    """The theme file (same format as themes/*.toml) for these colors; `noir`
    is the text of themes/noir.toml, for an image without any color."""
    colors = list(colors)
    if not any(_chroma(color) >= GRAY for color in colors):
        return noir
    made = seed(colors)
    try:
        theme = build_theme(made)
    except BuildError:
        made.pop("slots", None)   # the accent stays the signature color, slots get defaults
        theme = build_theme(made)
    return render(theme, "Wallpaper", f"Colors of {source}", "the wallpaper")
