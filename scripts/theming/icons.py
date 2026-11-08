"""Icon theme of the desktop: FairyWren (gitlab.com/FreshDoctor/FairyWren-Icons,
GPL-3.0, downloaded by `tfem icons fetch`, never bundled).

`icons.theme = "FairyWren"` picks FairyWren_Dark or FairyWren_Light from the
palette; any other value is used as the icon theme's name. The folders take
the FairyWren color that looks closest to the accent, or the one set in
`icons.folders`.
"""
from __future__ import annotations

from .colors import Color

FAIRYWREN = "FairyWren"
# The folder colors FairyWren ships (FairyWren_Dark/places/colours/).
FOLDER_COLORS = (
    "adwaita", "black", "blue", "bluegrey", "breeze", "brown", "carmine", "cyan", "darkcyan",
    "deeporange", "green", "grey", "indigo", "magenta", "multi", "nordic", "orange", "palebrown",
    "paleorange", "pine", "pink", "red", "teal", "violet", "white", "xpress", "yaru", "yellow",
)
# Color of the front of each folder.svg, measured on FairyWren_Dark
# (2026-11-08). Left out: multi and xpress (same as blue and yellow), and the
# distribution ones (adwaita, yaru): they can still be chosen in icons.folders.
MEASURED = {
    "black": "#383838", "blue": "#088cfd", "bluegrey": "#4a606b", "breeze": "#3c9ccf",
    "brown": "#8e6b43", "carmine": "#a43132", "cyan": "#39adbf", "darkcyan": "#2d6a73",
    "deeporange": "#e75d3b", "green": "#679944", "grey": "#757474", "indigo": "#5061c5",
    "magenta": "#c84d9f", "nordic": "#415d5e", "orange": "#d9834d", "palebrown": "#877562",
    "paleorange": "#cf8c64", "pine": "#4c8063", "pink": "#d5577a", "red": "#e24245",
    "teal": "#359283", "violet": "#7749b5", "white": "#b9bbbc", "yellow": "#f0b453",
}
# Accents are often lighter than any folder: lightness counts for a quarter,
# so a lavender accent gets violet folders, not white ones.
_LIGHTNESS_WEIGHT = 0.25


def theme_name(setting: str, variant: str) -> str:
    """The icon theme to use: FairyWren's dark or light half, or the setting."""
    if setting == FAIRYWREN:
        return f"{FAIRYWREN}_{'Light' if variant == 'light' else 'Dark'}"
    return setting


def folder_color(accent: Color) -> str:
    """The FairyWren folder color closest to `accent` (OKLab distance)."""
    lightness, a, b = oklab(accent)

    def distance(name: str) -> float:
        other = oklab(Color.parse(MEASURED[name]))
        return (_LIGHTNESS_WEIGHT * (other[0] - lightness)) ** 2 + (other[1] - a) ** 2 + (other[2] - b) ** 2

    return min(MEASURED, key=distance)


def oklab(color: Color) -> tuple[float, float, float]:
    """OKLab coordinates (Björn Ottosson's formulas): distances match how
    different two colors look."""
    def linear(channel: int) -> float:
        value = channel / 255
        return value / 12.92 if value <= 0.04045 else ((value + 0.055) / 1.055) ** 2.4

    r, g, b = linear(color.r), linear(color.g), linear(color.b)
    l = (0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b) ** (1 / 3)
    m = (0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b) ** (1 / 3)
    s = (0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b) ** (1 / 3)
    return (0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s,
            1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s,
            0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s)
