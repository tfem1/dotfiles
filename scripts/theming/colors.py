"""Color type: hex parsing and the output formats used by filters."""
from __future__ import annotations

import re
from dataclasses import dataclass

_HEX = re.compile(r"#([0-9a-fA-F]{6})([0-9a-fA-F]{2})?")


@dataclass(frozen=True)
class Color:
    r: int
    g: int
    b: int
    a: float = 1.0

    @classmethod
    def parse(cls, text: object) -> Color:
        """Parse "#rrggbb" or "#rrggbbaa"; raise ValueError otherwise."""
        match = _HEX.fullmatch(text.strip()) if isinstance(text, str) else None
        if not match:
            raise ValueError(f"invalid color {text!r} (expected #rrggbb or #rrggbbaa)")
        rgb, alpha = match.groups()
        return cls(
            int(rgb[0:2], 16),
            int(rgb[2:4], 16),
            int(rgb[4:6], 16),
            int(alpha, 16) / 255 if alpha else 1.0,
        )

    def with_alpha(self, alpha: float) -> Color:
        if not 0.0 <= alpha <= 1.0:
            raise ValueError(f"alpha must be between 0 and 1, got {alpha}")
        return Color(self.r, self.g, self.b, alpha)

    @property
    def alpha_byte(self) -> int:
        return round(self.a * 255)

    def _rgb_hex(self) -> str:
        return f"{self.r:02x}{self.g:02x}{self.b:02x}"

    # Output formats ---------------------------------------------------------

    def hex(self) -> str:
        """#rrggbb, followed by aa only when the color is transparent."""
        alpha = "" if self.alpha_byte == 255 else f"{self.alpha_byte:02x}"
        return f"#{self._rgb_hex()}{alpha}"

    def strip(self) -> str:
        """Like hex(), without the # (foot, some ini files)."""
        return self.hex()[1:]

    def hypr(self) -> str:
        """Hyprland / hyprlock format: rgba(rrggbbaa)."""
        return f"rgba({self._rgb_hex()}{self.alpha_byte:02x})"

    def argb(self) -> str:
        """Qt / QML format: #aarrggbb (alpha comes first)."""
        return f"#{self.alpha_byte:02x}{self._rgb_hex()}"

    def rgb(self) -> str:
        """Decimal channels for rgb()/rgba() in CSS: "r, g, b"."""
        return f"{self.r}, {self.g}, {self.b}"

    def sgr(self) -> str:
        """Terminal true-color foreground code: "38;2;r;g;b" (fastfetch colors)."""
        return f"38;2;{self.r};{self.g};{self.b}"

    def __str__(self) -> str:
        return self.hex()
