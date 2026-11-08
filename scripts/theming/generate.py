"""`generate` command: validate the settings, then render every target of the manifest."""
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
        print(f"error: invalid settings in {paths.pretty(error.source)}:", file=sys.stderr)
        for problem in error.problems:
            print(f"  - {problem}", file=sys.stderr)
        return 1
    except (PaletteError, ManifestError, ValueError) as error:
        print(f"error: {error}", file=sys.stderr)
        return 1

    user_theme = paths.user_dir / "theme.toml"
    origin = paths.pretty(user_theme) if user_theme.exists() else "defaults"
    print(f"Theme {palette.name} ({palette.variant}), settings from {origin}")
    if args.dry_run:
        print("Dry run: nothing is written.")

    context = build_context(theme, palette, paths, config)
    writer = Writer(paths, dry_run=args.dry_run)
    results = [_run(target, context, writer, paths, args, env) for target in targets]
    writer.save()
    _report(results, writer, paths)
    return 2 if any(result.status == "failed" for result in results) else 0


def _parse(argv: list[str] | None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(prog="generate", description="Render theme files from theme.toml.")
    parser.add_argument("--root", type=Path, default=DEFAULT_ROOT, help=argparse.SUPPRESS)
    parser.add_argument("--dry-run", action="store_true", help="show what would change, write nothing")
    parser.add_argument("--only", metavar="NAME[,NAME]", help="render only these targets")
    parser.add_argument("--all", action="store_true", help="render targets even if their app is not installed")
    return parser.parse_args(argv)


def _select(targets: list[Target], only: str | None) -> list[Target]:
    if not only:
        return targets
    wanted = {name.strip() for name in only.split(",") if name.strip()}
    known = {target.name for target in targets}
    if unknown := sorted(wanted - known):
        raise ValueError(f"unknown target(s): {', '.join(unknown)} (available: {', '.join(sorted(known))})")
    return [target for target in targets if target.name in wanted]


def _run(target: Target, context: dict, writer: Writer, paths: Paths,
         args: argparse.Namespace, env: Mapping[str, str]) -> Result:
    installed = not target.needs or shutil.which(target.needs, path=env.get("PATH")) is not None
    if not installed and not args.all:
        return Result(target, "skipped", f"{target.needs} not installed")
    if target.needs_dir and not target.needs_dir.is_dir():
        return Result(target, "skipped", f"{paths.pretty(target.needs_dir)} not set up")
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
        notes.append(f"include {included} in {paths.pretty(target.include.into)}")
    if target.include and included == "missing":
        notes.append(f"{paths.pretty(target.include.into)} not found: add '{target.include.line}' to it")
    changed = status != "unchanged" or included in ("added", "updated")
    # No reload for an app that is not installed (target rendered because of --all).
    if changed and target.reload and installed and not args.dry_run:
        # The command may use theme values too, e.g. {{ gtk.color_scheme | quote }}.
        try:
            command = render(target.reload, context, source=f"targets.toml [{target.name}] reload")
        except TemplateError as error:
            return Result(target, status, f"reload not run: {error}")
        notes.append(_reload(command))
    return Result(target, status, "; ".join(notes))


def _reload(command: str) -> str:
    try:
        done = subprocess.run(command, shell=True, capture_output=True, text=True, timeout=15)
    except subprocess.TimeoutExpired:
        return f"reload timed out: {command}"
    if done.returncode != 0:
        detail = (done.stderr or done.stdout).strip().splitlines()
        return f"reload failed ({command}): {detail[-1] if detail else done.returncode}"
    return "reloaded"


def _print_diff(path: Path, text: str, paths: Paths) -> None:
    current = path.read_text().splitlines(keepends=True) if path.exists() else []
    name = paths.pretty(path)
    sys.stdout.writelines(difflib.unified_diff(current, text.splitlines(keepends=True), name, f"{name} (new)"))


def _report(results: list[Result], writer: Writer, paths: Paths) -> None:
    width = max((len(result.target.name) for result in results), default=0)
    for result in results:
        where = paths.pretty(result.target.output) if result.status not in ("skipped", "failed") else ""
        note = f"  ({result.note})" if result.note and where else result.note
        print(f"  {result.status:<9}  {result.target.name:<{width}}  {where}{note}".rstrip())
    if writer.backups:
        print(f"Backups saved in {paths.pretty(writer.backup_dir)}")
