"""Targets manifest (templates/targets.toml): which template produces which file."""
from __future__ import annotations

import re
import tomllib
from dataclasses import dataclass
from pathlib import Path

from .paths import Paths

_TARGET_KEYS = {"template", "output", "needs", "needs_dir", "reload", "include"}
_INCLUDE_KEYS = {"into", "line", "comment", "comment_end", "position", "create"}
_PLACEHOLDER = re.compile(r"\{[a-z_]+\}")


class ManifestError(Exception):
    """Unreadable manifest or invalid entry."""


@dataclass(frozen=True)
class Include:
    into: Path              # app config that must load the generated file
    line: str               # line that loads it (include, require, @import...)
    comment: str = "#"      # comment prefix, used for the markers
    comment_end: str = ""   # closes the comment where needed ("*/" in CSS)
    position: str = "end"   # "end" or "start" (CSS needs @import at the top)
    create: bool = False    # create the app config when it does not exist


@dataclass(frozen=True)
class Target:
    name: str
    template: Path
    output: Path
    needs: str | None = None
    needs_dir: Path | None = None   # set up by another command; skipped until then
    reload: str | None = None
    include: Include | None = None


def load_targets(paths: Paths, shell_name: str) -> list[Target]:
    manifest = paths.root / "templates/targets.toml"
    try:
        with manifest.open("rb") as handle:
            data = tomllib.load(handle)
    except (OSError, tomllib.TOMLDecodeError) as error:
        raise ManifestError(f"cannot read {manifest}: {error}") from None
    return [_target(name, entry, paths, shell_name) for name, entry in data.items()]


def _target(name: str, entry: object, paths: Paths, shell: str) -> Target:
    where = f"targets.toml [{name}]"
    if not isinstance(entry, dict):
        raise ManifestError(f"{where}: expected a table")
    _check_keys(where, entry, _TARGET_KEYS, required={"template", "output"})
    template = paths.root / "templates" / entry["template"]
    if not template.is_file():
        raise ManifestError(f"{where}: template {template} does not exist")
    include = entry.get("include")
    return Target(
        name=name,
        template=template,
        output=_expand(where, entry["output"], paths, shell),
        needs=entry.get("needs"),
        needs_dir=_expand(where, entry["needs_dir"], paths, shell) if "needs_dir" in entry else None,
        reload=entry.get("reload"),
        include=_include(where, include, paths, shell) if include is not None else None,
    )


def _include(where: str, entry: object, paths: Paths, shell: str) -> Include:
    if not isinstance(entry, dict):
        raise ManifestError(f"{where}: include must be a table")
    _check_keys(f"{where} include", entry, _INCLUDE_KEYS, required={"into", "line"})
    position = entry.get("position", "end")
    if position not in ("end", "start"):
        raise ManifestError(f"{where}: include.position must be 'end' or 'start'")
    return Include(
        into=_expand(where, entry["into"], paths, shell),
        line=entry["line"],
        comment=entry.get("comment", "#"),
        comment_end=entry.get("comment_end", ""),
        position=position,
        create=bool(entry.get("create", False)),
    )


def _expand(where: str, text: str, paths: Paths, shell: str) -> Path:
    value = (text.replace("{config}", str(paths.config_home)).replace("{data}", str(paths.data_home))
             .replace("{sddm}", str(paths.sddm_dir)).replace("{shell}", shell))
    if leftover := _PLACEHOLDER.search(value):
        raise ManifestError(f"{where}: unknown placeholder {leftover.group()}")
    path = Path(value)
    if not path.is_absolute():
        raise ManifestError(f"{where}: '{text}' must start with {{config}}, {{data}} or be absolute")
    return path


def _check_keys(where: str, entry: dict, allowed: set[str], required: set[str]) -> None:
    if unknown := sorted(set(entry) - allowed):
        raise ManifestError(f"{where}: unknown key(s) {', '.join(unknown)}")
    if missing := sorted(required - set(entry)):
        raise ManifestError(f"{where}: missing key(s) {', '.join(missing)}")
