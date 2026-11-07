"""Emplacements utilisés par la génération, selon les conventions XDG."""
from __future__ import annotations

import os
from dataclasses import dataclass
from pathlib import Path
from typing import Mapping

# Nom du dossier projet dans ~/.config et ~/.local/state (jamais affiché dans le desktop).
PROJECT_DIR = "tfem"


@dataclass(frozen=True)
class Paths:
    root: Path         # le repo : défauts, thèmes, templates
    home: Path         # $HOME, pour afficher les chemins en « ~/… »
    config_home: Path  # $XDG_CONFIG_HOME, là où vivent les configs des apps
    user_dir: Path     # réglages personnels : theme.toml, config.json, themes/
    state_dir: Path    # backups et fichiers d'état, jamais édités à la main

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
        """Affiche un chemin avec « ~ » à la place du dossier personnel."""
        try:
            return "~/" + str(Path(path).relative_to(self.home))
        except ValueError:
            return str(path)
