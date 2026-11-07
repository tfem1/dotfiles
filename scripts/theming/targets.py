"""Manifeste des cibles (templates/targets.toml) : quel template produit quel fichier."""
from __future__ import annotations

import re
import tomllib
from dataclasses import dataclass
from pathlib import Path

from .paths import Paths

_TARGET_KEYS = {"template", "output", "needs", "reload", "include"}
_INCLUDE_KEYS = {"into", "line", "comment", "position", "create"}
_PLACEHOLDER = re.compile(r"\{[a-z_]+\}")


class ManifestError(Exception):
    """Manifeste illisible ou entrée invalide."""


@dataclass(frozen=True)
class Include:
    into: Path              # config de l'app qui doit charger le fichier généré
    line: str               # ligne qui le charge (include, require, @import…)
    comment: str = "#"      # préfixe de commentaire, pour les marqueurs
    position: str = "end"   # "end" ou "start" (CSS exige @import en tête)
    create: bool = False    # créer la config de l'app si elle n'existe pas


@dataclass(frozen=True)
class Target:
    name: str
    template: Path
    output: Path
    needs: str | None = None
    reload: str | None = None
    include: Include | None = None


def load_targets(paths: Paths, shell_name: str) -> list[Target]:
    manifest = paths.root / "templates/targets.toml"
    try:
        with manifest.open("rb") as handle:
            data = tomllib.load(handle)
    except (OSError, tomllib.TOMLDecodeError) as error:
        raise ManifestError(f"impossible de lire {manifest} : {error}") from None
    return [_target(name, entry, paths, shell_name) for name, entry in data.items()]


def _target(name: str, entry: object, paths: Paths, shell: str) -> Target:
    where = f"targets.toml [{name}]"
    if not isinstance(entry, dict):
        raise ManifestError(f"{where} : doit être une table")
    _check_keys(where, entry, _TARGET_KEYS, required={"template", "output"})
    template = paths.root / "templates" / entry["template"]
    if not template.is_file():
        raise ManifestError(f"{where} : le template {template} n'existe pas")
    include = entry.get("include")
    return Target(
        name=name,
        template=template,
        output=_expand(where, entry["output"], paths, shell),
        needs=entry.get("needs"),
        reload=entry.get("reload"),
        include=_include(where, include, paths, shell) if include is not None else None,
    )


def _include(where: str, entry: object, paths: Paths, shell: str) -> Include:
    if not isinstance(entry, dict):
        raise ManifestError(f"{where} : include doit être une table")
    _check_keys(f"{where} include", entry, _INCLUDE_KEYS, required={"into", "line"})
    position = entry.get("position", "end")
    if position not in ("end", "start"):
        raise ManifestError(f"{where} : include.position doit valoir 'end' ou 'start'")
    return Include(
        into=_expand(where, entry["into"], paths, shell),
        line=entry["line"],
        comment=entry.get("comment", "#"),
        position=position,
        create=bool(entry.get("create", False)),
    )


def _expand(where: str, text: str, paths: Paths, shell: str) -> Path:
    value = text.replace("{config}", str(paths.config_home)).replace("{shell}", shell)
    if leftover := _PLACEHOLDER.search(value):
        raise ManifestError(f"{where} : placeholder inconnu {leftover.group()}")
    path = Path(value)
    if not path.is_absolute():
        raise ManifestError(f"{where} : '{text}' doit commencer par {{config}} ou être un chemin absolu")
    return path


def _check_keys(where: str, entry: dict, allowed: set[str], required: set[str]) -> None:
    if unknown := sorted(set(entry) - allowed):
        raise ManifestError(f"{where} : clé(s) inconnue(s) {', '.join(unknown)}")
    if missing := sorted(required - set(entry)):
        raise ManifestError(f"{where} : clé(s) manquante(s) {', '.join(missing)}")
