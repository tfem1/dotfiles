"""Color checks: hue classes on the color wheel, the neighbour rule, WCAG contrast."""
from __future__ import annotations

import colorsys
from typing import Mapping

from .colors import Color

# Centre of each hue on the wheel, in degrees, in wheel order (red follows purple).
WHEEL = (("red", 0), ("orange", 30), ("yellow", 55), ("green", 110),
         ("cyan", 180), ("blue", 220), ("purple", 285))
NAMES = tuple(name for name, _ in WHEEL)
SLOT_ROLES = {"base08": "red", "base09": "orange", "base0A": "yellow", "base0B": "green",
              "base0C": "cyan", "base0D": "blue", "base0E": "purple"}
MIN_SATURATION = 0.10  # below this a color is grey: its hue means nothing


def hls(color: Color) -> tuple[float, float, float]:
    """Hue (0-1), lightness and saturation of a color."""
    return colorsys.rgb_to_hls(color.r / 255, color.g / 255, color.b / 255)


def from_hls(hue: float, lightness: float, saturation: float) -> Color:
    r, g, b = colorsys.hls_to_rgb(hue % 1.0, min(max(lightness, 0.0), 1.0), min(max(saturation, 0.0), 1.0))
    return Color(round(r * 255), round(g * 255), round(b * 255))


def readable(color: Color, background: Color, variant: str, minimum: float) -> Color:
    """Keeps hue and saturation, moves lightness away from the background until
    the contrast reaches `minimum`. ValueError if it never does."""
    hue, lightness, saturation = hls(color)
    step = 0.01 if variant == "dark" else -0.01
    while contrast(color, background) < minimum:
        lightness += step
        if not 0.0 <= lightness <= 1.0:
            raise ValueError(f"cannot make {color.hex()} readable on {background.hex()}")
        color = from_hls(hue, lightness, saturation)
    return color


def hue_class(color: Color) -> str | None:
    hue, _, saturation = hls(color)
    if saturation < MIN_SATURATION:
        return None
    degrees = hue * 360
    return min(WHEEL, key=lambda item: min(abs(degrees - item[1]), 360 - abs(degrees - item[1])))[0]


def fits(role: str, color: Color) -> bool:
    """True when the color lands on its own hue or a neighbouring one."""
    found = hue_class(color)
    if found is None:
        return True
    distance = abs(NAMES.index(role) - NAMES.index(found))
    return min(distance, len(NAMES) - distance) <= 1


def hue_problems(colors: Mapping[str, Color]) -> list[str]:
    return [
        f"{slot} should be {role}, looks {hue_class(colors[slot])}"
        for slot, role in SLOT_ROLES.items()
        if slot in colors and not fits(role, colors[slot])
    ]


def luminance(color: Color) -> float:
    """Relative luminance as defined by WCAG 2."""
    def linear(channel: int) -> float:
        value = channel / 255
        return value / 12.92 if value <= 0.04045 else ((value + 0.055) / 1.055) ** 2.4

    return 0.2126 * linear(color.r) + 0.7152 * linear(color.g) + 0.0722 * linear(color.b)


def contrast(first: Color, second: Color) -> float:
    high, low = sorted((luminance(first), luminance(second)), reverse=True)
    return (high + 0.05) / (low + 0.05)
