"""The theme's three colors: its accent and two companions of the same
family. Shell modules only use these three (and red for alerts), so a theme
stays minimal: a forest theme is greens, the cat theme warm oranges.

A theme file may set `accent2` and `accent3` itself (a second color it
is known for, say); otherwise they are derived from the accent:
- accent2: same hue, a step lighter, or a step deeper when the accent is
  already light (so it never fades to white), a little softer;
- accent3: the neighbouring hue (about 14 degrees away), a little softer.
Both stay readable on the background (WCAG 4.5:1), like the accent.
"""
from __future__ import annotations

from .colors import Color
from .hues import hls, from_hls, readable

MINIMUM_CONTRAST = 4.5
HUE_STEP = 0.04        # about 14 degrees: a neighbour, never another family
STEP = 0.08
LIGHT = 0.70           # above this lightness (dark themes), accent2 goes deeper


def companions(accent: Color, background: Color, variant: str) -> tuple[Color, Color]:
    hue, lightness, saturation = hls(accent)
    if variant == "dark":
        step = -STEP if lightness > LIGHT else STEP
    else:
        step = STEP if lightness < 1 - LIGHT else -STEP
    second = from_hls(hue, lightness + step, saturation * 0.9)
    third = from_hls(hue + HUE_STEP, lightness, saturation * 0.85)
    return (readable(second, background, variant, MINIMUM_CONTRAST),
            readable(third, background, variant, MINIMUM_CONTRAST))
