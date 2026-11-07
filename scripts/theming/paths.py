"""Locations used by the generator, following the XDG conventions."""
from __future__ import annotations

import os
from dataclasses import dataclass
from pathlib import Path
from typing import Mapping

# Project folder name in ~/.config and ~/.local/state (never shown on the desktop).
PROJECT_DIR = "tfem"


@dataclass(frozen=True)
class Paths:
    root: Path         # the repository: defaults, themes, templates
    home: Path         # $HOME, to print paths as "~/..."
    config_home: Path  # $XDG_CONFIG_HOME, where app configs live
    user_dir: Path     # personal settings: theme.toml, config.json, themes/
    state_dir: Path    # backups and state files, never edited by hand

    @classmethod
    def from_env(cls, root: Path, env: Mapping[str, str] = os.environ) -> Paths:
        home = Path(env.get("HOME") or Path.home())
        config_home = Path(env.get("XDG_CONFIG_HOME") or home / ".config")
        state_home = Path(env.get("XDG_STATE_HOME") or home / ".local/state")
        return cls(
            root=Path(root).resolve(),
            home=home,
            config_home=config_home,
            user_dir=config_home / PROJECT_DIR,
            state_dir=state_home / PROJECT_DIR,
        )

    def pretty(self, path: Path) -> str:
        """Print a path with "~" in place of the home folder."""
        try:
            return "~/" + str(Path(path).relative_to(self.home))
        except ValueError:
            return str(path)
