"""The shortcuts of keybinds.toml, with the keys chosen in config.json
(keys.<id>), written for Hyprland (a Lua table read by hypr/config/keybinds.lua),
Sway (bindsym lines) and Niri (a binds block).

A key is written "SUPER + SHIFT + C": modifiers among SUPER, CTRL, ALT and
SHIFT, then one key. A key chosen for an action takes it from the action that
had it by default, which is then left without a key (to be given another); a
key of the window manager's own shortcuts (keybinds.toml `reserved`) is not
taken.
"""
from __future__ import annotations

import re
import tomllib
from pathlib import Path
from typing import Mapping

ROOT = Path(__file__).resolve().parents[2]
MODIFIERS = ("SUPER", "CTRL", "ALT", "SHIFT")
# Key names -> xkb keysym names (Hyprland, Sway and Niri all use these).
NAMED = {
    "RETURN": "Return", "SPACE": "space", "TAB": "Tab", "ESCAPE": "Escape", "PRINT": "Print",
    "SLASH": "slash", "BACKSLASH": "backslash", "COMMA": "comma", "PERIOD": "period",
    "MINUS": "minus", "EQUAL": "equal", "SEMICOLON": "semicolon", "APOSTROPHE": "apostrophe",
    "GRAVE": "grave", "BRACKETLEFT": "bracketleft", "BRACKETRIGHT": "bracketright",
    "BACKSPACE": "BackSpace", "DELETE": "Delete", "INSERT": "Insert", "HOME": "Home", "END": "End",
    "PAGE_UP": "Prior", "PAGE_DOWN": "Next", "LEFT": "Left", "RIGHT": "Right", "UP": "Up", "DOWN": "Down",
}
KEY = re.compile(r"[A-Z0-9]|F([1-9]|1[0-2])|" + "|".join(NAMED))
SWAY_MODS = {"SUPER": "$mod", "CTRL": "Ctrl", "ALT": "Alt", "SHIFT": "Shift"}
NIRI_MODS = {"SUPER": "Mod", "CTRL": "Ctrl", "ALT": "Alt", "SHIFT": "Shift"}


def parse(text: str) -> tuple[tuple[str, ...], str]:
    """("SUPER", "SHIFT"), "C" from "super + shift + c"; ValueError if invalid."""
    parts = [part.strip().upper() for part in str(text).split("+")]
    *mods, key = parts
    if not KEY.fullmatch(key) or any(mod not in MODIFIERS for mod in mods) or len(set(mods)) != len(mods):
        raise ValueError(f"'{text}': expected modifiers (SUPER, CTRL, ALT, SHIFT) then a key, "
                         "joined by ' + ', like 'SUPER + SHIFT + C'")
    return tuple(mod for mod in MODIFIERS if mod in mods), key


def canonical(text: str) -> str:
    mods, key = parse(text)
    return " + ".join((*mods, key))


def load(path: Path = ROOT / "keybinds.toml") -> tuple[list[dict], list[str]]:
    data = tomllib.loads(path.read_text())
    actions = [dict(action, key=canonical(action["key"]), locked=bool(action.get("locked")))
               for action in data["action"]]
    return actions, [canonical(key) for key in data.get("reserved", [])]


def resolve(config: Mapping[str, object], path: Path = ROOT / "keybinds.toml") -> list[dict]:
    """The actions with their keys: the chosen ones first, then the defaults
    no chosen key took ("" when taken)."""
    actions, reserved = load(path)
    chosen = {action["id"]: canonical(str(config[f"keys.{action['id']}"]))
              for action in actions if f"keys.{action['id']}" in config}
    # A key of the window manager's own shortcuts is not taken: the default stays.
    chosen = {name: key for name, key in chosen.items() if key not in reserved}
    taken = set(chosen.values())
    for action in actions:
        if action["id"] in chosen:
            action["key"] = chosen[action["id"]]
        elif action["key"] in taken:
            action["key"] = ""
        taken.add(action["key"])
    return actions


def _xkb(key: str, lower_letters: bool) -> str:
    if key in NAMED:
        return NAMED[key]
    return key.lower() if lower_letters and len(key) == 1 else key


def _command(action: dict, shell: str) -> str:
    return action["run"].replace("{shell}", shell).replace("{cli}", "~/.local/bin/tfem")


def _quote(text: str) -> str:
    return '"' + text.replace("\\", "\\\\").replace('"', '\\"') + '"'


def hyprland(actions: list[dict], shell: str) -> str:
    rows = [f"  {{ key = {_quote(' + '.join((*parse(a['key'])[0], _xkb(parse(a['key'])[1], False))))}, "
            f"run = {_quote(_command(a, shell))}, description = {_quote(a['title'])}, "
            f"locked = {str(a['locked']).lower()} }},"
            for a in actions if a["key"]]
    return "return {\n" + "\n".join(rows) + "\n}"


def sway(actions: list[dict], shell: str) -> str:
    lines = []
    for action in (a for a in actions if a["key"]):
        mods, key = parse(action["key"])
        combo = "+".join([SWAY_MODS[mod] for mod in mods] + [_xkb(key, True)])
        lines.append(f"bindsym {'--locked ' if action['locked'] else ''}{combo} exec {_command(action, shell)}")
    return "\n".join(lines)


def niri(actions: list[dict], shell: str) -> str:
    lines = []
    for action in (a for a in actions if a["key"]):
        mods, key = parse(action["key"])
        combo = "+".join([NIRI_MODS[mod] for mod in mods] + [_xkb(key, False)])
        locked = " allow-when-locked=true" if action["locked"] else ""
        lines.append(f"    {combo}{locked} {{ spawn-sh {_quote(_command(action, shell))}; }}")
    return "binds {\n" + "\n".join(lines) + "\n}"


def context(config: Mapping[str, object]) -> dict[str, object]:
    actions = resolve(config)
    shell = str(config.get("shell.name", "desktop"))
    return {"keys.hyprland": hyprland(actions, shell), "keys.sway": sway(actions, shell),
            "keys.niri": niri(actions, shell),
            "keys.list": [{"id": a["id"], "title": a["title"], "key": a["key"]} for a in actions]}
