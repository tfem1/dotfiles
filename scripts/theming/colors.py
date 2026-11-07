"""Type Color : lecture d'un hex et formats de sortie utilisés par les filtres."""
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
        """Lit "#rrggbb" ou "#rrggbbaa" ; lève ValueError sinon."""
        match = _HEX.fullmatch(text.strip()) if isinstance(text, str) else None
        if not match:
            raise ValueError(f"couleur invalide {text!r} (attendu : #rrggbb ou #rrggbbaa)")
        rgb, alpha = match.groups()
        return cls(
            int(rgb[0:2], 16),
            int(rgb[2:4], 16),
            int(rgb[4:6], 16),
            int(alpha, 16) / 255 if alpha else 1.0,
        )

    def with_alpha(self, alpha: float) -> Color:
        if not 0.0 <= alpha <= 1.0:
            raise ValueError(f"alpha doit être entre 0 et 1 (reçu : {alpha})")
        return Color(self.r, self.g, self.b, alpha)

    @property
    def alpha_byte(self) -> int:
        return round(self.a * 255)

    def _rgb_hex(self) -> str:
        return f"{self.r:02x}{self.g:02x}{self.b:02x}"

    # Formats de sortie ------------------------------------------------------

    def hex(self) -> str:
        """#rrggbb, suivi de aa seulement si la couleur est transparente."""
        alpha = "" if self.alpha_byte == 255 else f"{self.alpha_byte:02x}"
        return f"#{self._rgb_hex()}{alpha}"

    def strip(self) -> str:
        """Comme hex(), sans le # (foot, certains fichiers ini)."""
        return self.hex()[1:]

    def hypr(self) -> str:
        """Format Hyprland / hyprlock : rgba(rrggbbaa)."""
        return f"rgba({self._rgb_hex()}{self.alpha_byte:02x})"

    def argb(self) -> str:
        """Format Qt / QML : #aarrggbb (l'alpha vient en premier)."""
        return f"#{self.alpha_byte:02x}{self._rgb_hex()}"

    def rgb(self) -> str:
        """Canaux décimaux pour rgb()/rgba() en CSS : "r, g, b"."""
        return f"{self.r}, {self.g}, {self.b}"

    def __str__(self) -> str:
        return self.hex()
