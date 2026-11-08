"""Screens: the modes `hyprctl monitors -j` offers, grouped for the Settings
window, and the Hyprland rules for the modes picked there.

A mode is "WIDTHxHEIGHT@RATE" (2560x1440@165.00), as `hl.monitor` takes it;
the rate keeps the decimals Hyprland lists, so it matches the exact mode.
"""
from __future__ import annotations

import json
import re
from typing import Mapping

MODE = re.compile(r"(\d{2,5})x(\d{2,5})@(\d{1,3}(?:\.\d{1,3})?)")
# Port names: DP-1, eDP-1, HDMI-A-1...
OUTPUT = re.compile(r"[A-Za-z0-9][A-Za-z0-9_-]{0,31}")
PREFIX = "display.modes."   # config.json: {"display": {"modes": {"DP-1": "..."}}}


def mode(width: int, height: int, rate: float) -> str:
    return f"{width}x{height}@{rate:.2f}"


def monitors(data: list[Mapping]) -> list[dict]:
    """Each screen with its resolutions, biggest first, and their rates,
    highest first ("165 Hz"); rates that round to the same Hz are one."""
    screens = []
    for screen in data:
        sizes: dict[tuple[int, int], dict[int, float]] = {}
        for text in screen.get("availableModes", []):
            if not (match := MODE.fullmatch(text.removesuffix("Hz"))):
                continue
            width, height, rate = int(match[1]), int(match[2]), float(match[3])
            rates = sizes.setdefault((width, height), {})
            rates[round(rate)] = max(rate, rates.get(round(rate), 0))
        width, height = int(screen.get("width", 0)), int(screen.get("height", 0))
        current = mode(width, height, float(screen.get("refreshRate", 0)))
        screens.append({
            "name": screen.get("name", ""),
            "description": screen.get("description", ""),
            "current": current,
            "size": f"{width}x{height}",
            "resolutions": [
                {"size": f"{w}x{h}",
                 "rates": [{"label": f"{hz} Hz", "mode": mode(w, h, rates[hz])}
                           for hz in sorted(rates, reverse=True)]}
                for (w, h), rates in sorted(sizes.items(), key=lambda item: -item[0][0] * item[0][1])
            ],
        })
    return screens


def chosen(config: Mapping[str, object]) -> dict[str, str]:
    """{"DP-1": "2560x1440@165.00"} from the flat config.json values."""
    return {key[len(PREFIX):]: str(value) for key, value in config.items() if key.startswith(PREFIX)}


def lua_rules(modes: Mapping[str, str]) -> str:
    """One `hl.monitor` per screen with a picked mode. Position and scale are
    those of the rule for every other screen (config/monitors.lua)."""
    if not modes:
        return "-- No mode picked: every screen uses its highest refresh rate."
    return "\n".join(
        f"hl.monitor({{ output = {json.dumps(name)}, mode = {json.dumps(value)}, "
        f'position = "auto", scale = 1 }})'
        for name, value in sorted(modes.items())
    )
