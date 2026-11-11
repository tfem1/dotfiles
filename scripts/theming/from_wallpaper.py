"""A theme made from a wallpaper's colors: a green wallpaper gives a green
theme, a blue one a blue theme.

The shell reads the image's main colors with Quickshell's ColorQuantizer (8
colors, each an equal share of the image) and passes them to `tfem
wallpapers set`. The hue that covers the most of the image (counting how
colorful each part is) becomes the theme's color, through the seeds of the
theme builder (builder.py), which makes every color readable:
- tint (backgrounds) and text: the darkest color of that hue in the image
  (the lightest for a light image, which gets a light theme);
- accent: the most vivid color of that hue covering a good part of it.
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


def _chroma(color: Color) -> float:
    _, a, b = oklab(color)
    return math.hypot(a, b)


def seed(colors: Iterable[Color]) -> dict:
    counts = Counter(color.hex() for color in colors)
    if not counts:
        raise ValueError("no colors")
    shares = {Color.parse(hex_): count / sum(counts.values()) for hex_, count in counts.items()}
    light = sum(oklab(color)[0] * share for color, share in shares.items()) > LIGHT_IMAGE
    # The color of the image: the hue that covers the most, counting how
    # colorful each part is (a green forest is green, a blue lake blue).
    weights: Counter = Counter()
    for color, share in shares.items():
        if _chroma(color) >= GRAY and (family := hue_class(color)):
            weights[family] += _chroma(color) * share
    if not weights:
        tint = max(shares, key=lambda color: shares[color])
        accent = Color.parse("#202020" if light else "#f0f0f0")
        return {"name": NAME, "variant": "light" if light else "dark", "tint": tint.hex(),
                "text": tint.hex(), "accent": accent.hex()}
    family = weights.most_common(1)[0][0]
    own = [color for color in shares if _chroma(color) >= GRAY and hue_class(color) == family]
    # Accent: the most vivid color of that hue that covers a good part.
    accent = max(own, key=lambda color: _chroma(color) * math.sqrt(shares[color]))
    # Backgrounds: the darkest color of that hue (the lightest for a light
    # image), so the whole theme has the color of the picture.
    tint = (max if light else min)(own, key=lambda color: oklab(color)[0])
    result = {"name": NAME, "variant": "light" if light else "dark", "tint": tint.hex(),
              "text": tint.hex(), "accent": accent.hex()}
    if family in SLOTS:
        result["slots"] = {family: accent.hex()}
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
