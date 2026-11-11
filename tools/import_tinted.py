"""Imports base16 schemes from tinted-theming/schemes (MIT, see
licenses/MIT-tinted-theming.txt) into themes/.

Usage: python3 tools/import_tinted.py PATH/TO/schemes/base16
The colors are copied unchanged. Each theme also gets its signature color
(the accent, picked below); when it is too pale or too dark to read on the
theme's background, only its lightness is moved until it reads (same hue).
A scheme whose hues sit in the wrong slots is refused, as for every theme.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from theming.colors import Color  # noqa: E402
from theming.hues import contrast, hue_problems, readable  # noqa: E402

# scheme -> (family, slot of the signature color, what it is)
PICKS = {
    "catppuccin-latte": ("Catppuccin", "base0E", "its mauve"),
    "dracula": ("Dracula", "base0D", "its purple"),
    "nord": ("Nord", "base0C", "its frost blue"),
    "gruvbox-dark-medium": ("Gruvbox", "base09", "its orange"),
    "tokyo-night-moon": ("Tokyo Night", "base0D", "its blue"),
    "solarized-dark": ("Solarized", "base0D", "its blue"),
    "onedark": ("One", "base0D", "its blue"),
}
SLOTS = tuple(f"base0{digit}" for digit in "0123456789ABCDEF")


def field(text: str, key: str) -> str:
    match = re.search(rf'^{key}:\s*"([^"]*)"', text, re.MULTILINE)
    if not match:
        raise ValueError(f"no {key}")
    return match.group(1)


def convert(scheme: Path, family: str, slot: str, what: str) -> str:
    text = scheme.read_text()
    colors = {key: Color.parse(value) for key, value in
              re.findall(r'^\s+(base0[0-9A-F]):\s*"(#[0-9a-fA-F]{6})"', text, re.MULTILINE)}
    if sorted(colors) != sorted(SLOTS):
        raise ValueError(f"{scheme.name}: incomplete palette")
    if problems := hue_problems(colors):
        raise ValueError(f"{scheme.name}: " + "; ".join(problems))
    name, variant, author = field(text, "name"), field(text, "variant"), field(text, "author")
    accent = colors[slot]
    note = "colors unchanged"
    if contrast(accent, colors["base00"]) < 4.5:
        accent = readable(accent, colors["base00"], variant, 4.5)
        note = f"colors unchanged, {what} made readable for the accent"
    lines = [
        f"# {name} — base16 scheme from tinted-theming/schemes (MIT), {note}.",
        f"# Signature color (accent): {what}. Imported by tools/import_tinted.py.",
        f'name    = "{name}"',
        f'family  = "{family}"',
        f'variant = "{variant}"',
        f'author  = "{author}"',
        f'accent  = "{accent.hex()}"',
        "",
        "[colors]",
        *(f'{key} = "{colors[key].hex()}"' for key in SLOTS),
    ]
    return "\n".join(lines) + "\n"


def main(argv: list[str]) -> int:
    if len(argv) != 1:
        print(__doc__.strip().splitlines()[2], file=sys.stderr)
        return 64
    source = Path(argv[0])
    for scheme, (family, slot, what) in PICKS.items():
        target = ROOT / "themes" / f"{scheme}.toml"
        target.write_text(convert(source / f"{scheme}.yaml", family, slot, what))
        print(target.relative_to(ROOT))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
