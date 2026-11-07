"""Commande `generate` : valide les réglages, puis produit chaque cible du manifeste."""
from __future__ import annotations

import argparse
import difflib
import os
import shutil
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Mapping

from .context import build_context
from .palette import PaletteError, resolve_palette
from .paths import Paths
from .settings import SettingsError, load_config, load_theme
from .targets import ManifestError, Target, load_targets
from .template import TemplateError, render
from .writer import Writer

DEFAULT_ROOT = Path(__file__).resolve().parents[2]

# Statuts internes → libellés affichés dans le rapport.
LABELS = {
    "unchanged": "inchangé", "created": "créé", "updated": "mis à jour",
    "skipped": "ignoré", "failed": "échec",
}


@dataclass
class Result:
    target: Target
    status: str  # unchanged | created | updated | skipped | failed
    note: str = ""


def main(argv: list[str] | None = None, env: Mapping[str, str] = os.environ) -> int:
    args = _parse(argv)
    paths = Paths.from_env(args.root, env)
    try:
        theme = load_theme(paths)
        config = load_config(paths)
        palette = resolve_palette(theme, paths)
        targets = _select(load_targets(paths, str(config["shell.name"])), args.only)
    except SettingsError as error:
        print(f"erreur : réglages invalides dans {paths.pretty(error.source)} :", file=sys.stderr)
        for problem in error.problems:
            print(f"  - {problem}", file=sys.stderr)
        return 1
    except (PaletteError, ManifestError, ValueError) as error:
        print(f"erreur : {error}", file=sys.stderr)
        return 1

    user_theme = paths.user_dir / "theme.toml"
    origin = paths.pretty(user_theme) if user_theme.exists() else "valeurs par défaut"
    print(f"Thème {palette.name} ({palette.variant}), réglages : {origin}")
    if args.dry_run:
        print("Simulation : rien n'est écrit.")

    context = build_context(theme, palette, paths)
    writer = Writer(paths, dry_run=args.dry_run)
    results = [_run(target, context, writer, paths, args, env) for target in targets]
    writer.save()
    _report(results, writer, paths)
    return 2 if any(result.status == "failed" for result in results) else 0


def _parse(argv: list[str] | None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(prog="generate", description="Génère les fichiers de thème depuis theme.toml.")
    parser.add_argument("--root", type=Path, default=DEFAULT_ROOT, help=argparse.SUPPRESS)
    parser.add_argument("--dry-run", action="store_true", help="montre ce qui changerait, sans rien écrire")
    parser.add_argument("--only", metavar="NOM[,NOM]", help="ne génère que ces cibles")
    parser.add_argument("--all", action="store_true", help="génère même si l'app n'est pas installée")
    return parser.parse_args(argv)


def _select(targets: list[Target], only: str | None) -> list[Target]:
    if not only:
        return targets
    wanted = {name.strip() for name in only.split(",") if name.strip()}
    known = {target.name for target in targets}
    if unknown := sorted(wanted - known):
        raise ValueError(f"cible(s) inconnue(s) : {', '.join(unknown)} (disponibles : {', '.join(sorted(known))})")
    return [target for target in targets if target.name in wanted]


def _run(target: Target, context: dict, writer: Writer, paths: Paths,
         args: argparse.Namespace, env: Mapping[str, str]) -> Result:
    installed = not target.needs or shutil.which(target.needs, path=env.get("PATH")) is not None
    if not installed and not args.all:
        return Result(target, "skipped", f"{target.needs} n'est pas installé")
    try:
        text = render(target.template.read_text(), context, source=paths.pretty(target.template))
        if args.dry_run:
            _print_diff(target.output, text, paths)
        status = writer.write_output(target.output, text)
        included = writer.ensure_include(target.name, target.include) if target.include else None
    except (TemplateError, OSError) as error:
        return Result(target, "failed", str(error))

    notes = []
    if target.include and included in ("added", "updated"):
        action = "ajouté" if included == "added" else "mis à jour"
        notes.append(f"include {action} dans {paths.pretty(target.include.into)}")
    if target.include and included == "missing":
        notes.append(f"{paths.pretty(target.include.into)} introuvable : ajoute-y '{target.include.line}'")
    changed = status != "unchanged" or included in ("added", "updated")
    # Pas de reload pour une app absente (cible rendue grâce à --all).
    if changed and target.reload and installed and not args.dry_run:
        notes.append(_reload(target.reload))
    return Result(target, status, "; ".join(notes))


def _reload(command: str) -> str:
    try:
        done = subprocess.run(command, shell=True, capture_output=True, text=True, timeout=15)
    except subprocess.TimeoutExpired:
        return f"rechargement trop long : {command}"
    if done.returncode != 0:
        detail = (done.stderr or done.stdout).strip().splitlines()
        return f"échec du rechargement ({command}) : {detail[-1] if detail else done.returncode}"
    return "rechargé"


def _print_diff(path: Path, text: str, paths: Paths) -> None:
    current = path.read_text().splitlines(keepends=True) if path.exists() else []
    name = paths.pretty(path)
    sys.stdout.writelines(difflib.unified_diff(current, text.splitlines(keepends=True), name, f"{name} (nouveau)"))


def _report(results: list[Result], writer: Writer, paths: Paths) -> None:
    width = max((len(result.target.name) for result in results), default=0)
    for result in results:
        where = paths.pretty(result.target.output) if result.status not in ("skipped", "failed") else ""
        note = f"  ({result.note})" if result.note and where else result.note
        print(f"  {LABELS[result.status]:<10}  {result.target.name:<{width}}  {where}{note}".rstrip())
    if writer.backups:
        print(f"Sauvegardes dans {paths.pretty(writer.backup_dir)}")
