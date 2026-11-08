"""Screens: resolution and refresh rate, for the Settings window (Display)
and the command line.

Usage: display.py list               the screens and their modes, as JSON
       display.py set NAME MODE      use MODE on screen NAME (2560x1440@165.00)
       display.py auto NAME          back to the highest refresh rate
The choice goes to config.json (display.modes), then `tfem generate` writes
~/.config/hypr/display.lua and reloads Hyprland, which applies it at once.
"""
from __future__ import annotations

import json
import os
import subprocess
import sys
from pathlib import Path
from typing import Mapping

from theming.display import MODE, OUTPUT, chosen, monitors  # noqa: E402  (scripts/ is on sys.path)
from theming.generate import main as generate  # noqa: E402
from theming.paths import Paths  # noqa: E402
from theming.settings import SettingsError, load_config  # noqa: E402
from theming.writer import write_atomic  # noqa: E402

ROOT = Path(__file__).resolve().parent.parent


def screens(env: Mapping[str, str]) -> list[dict]:
    """The screens Hyprland drives now ([] when it is not running)."""
    try:
        done = subprocess.run(["hyprctl", "monitors", "-j"], capture_output=True, text=True,
                              timeout=5, env=dict(env))
        return monitors(json.loads(done.stdout)) if done.returncode == 0 else []
    except (OSError, subprocess.TimeoutExpired, json.JSONDecodeError, TypeError, AttributeError):
        return []


def listing(paths: Paths, env: Mapping[str, str]) -> dict:
    return {"monitors": screens(env), "chosen": chosen(load_config(paths))}


def write_mode(paths: Paths, name: str, mode: str | None) -> None:
    """Sets (or with None removes) the mode of one screen in your config.json."""
    if not OUTPUT.fullmatch(name):
        raise ValueError(f"'{name}' is not a screen name (like DP-1 or HDMI-A-1)")
    if mode is not None and not MODE.fullmatch(mode):
        raise ValueError(f"'{mode}' is not a mode (like 2560x1440@165.00)")
    path = paths.user_dir / "config.json"
    config = json.loads(path.read_text()) if path.exists() else {}
    modes = config.setdefault("display", {}).setdefault("modes", {})
    if mode is None:
        modes.pop(name, None)
    else:
        modes[name] = mode
    write_atomic(path, json.dumps(config, indent=2) + "\n")
    load_config(paths)  # the file stays valid


def main(argv: list[str] | None = None, env: Mapping[str, str] = os.environ) -> int:
    args = list(sys.argv[1:] if argv is None else argv)
    paths = Paths.from_env(ROOT, env)
    try:
        if args == ["list"]:
            print(json.dumps(listing(paths, env)))
            return 0
        if (args[:1] == ["set"] and len(args) == 3) or (args[:1] == ["auto"] and len(args) == 2):
            name, mode = args[1], (args[2] if args[0] == "set" else None)
            write_mode(paths, name, mode)
            print(f"{name}: {mode or 'highest refresh rate'}")
            return generate(["--root", str(ROOT), "--only", "hyprland-display"], env=env)
    except (OSError, ValueError, SettingsError) as error:
        print(f"error: {error}", file=sys.stderr)
        return 1
    print("\n".join(__doc__.strip().splitlines()[3:6]), file=sys.stderr)
    return 64


if __name__ == "__main__":
    sys.exit(main())
