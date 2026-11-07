"""Safe writing: comparison, backup, atomic writes and include blocks."""
from __future__ import annotations

import hashlib
import json
import os
import re
import shutil
import tempfile
import time
from pathlib import Path

from .paths import Paths
from .targets import Include

REGISTRY = "generated.json"


def write_atomic(path: Path, text: str) -> None:
    """Write to a temporary file next to the target, then rename it: never a half-written file."""
    path.parent.mkdir(parents=True, exist_ok=True)
    handle, temporary = tempfile.mkstemp(dir=path.parent, prefix=f".{path.name}.")
    try:
        with os.fdopen(handle, "w") as stream:
            stream.write(text)
        os.replace(temporary, path)
    except BaseException:
        Path(temporary).unlink(missing_ok=True)
        raise


def include_block(name: str, include: Include) -> str:
    mark = include.comment
    return f"{mark} >>> generated: {name} >>>\n{include.line}\n{mark} <<< generated: {name} <<<\n"


class Writer:
    """Apply one generation run and remember what it produced (one digest per file)."""

    def __init__(self, paths: Paths, dry_run: bool = False):
        self.paths = paths
        self.dry_run = dry_run
        self.backup_dir = paths.state_dir / "backups" / time.strftime("%Y%m%d-%H%M%S")
        self.backups: list[Path] = []
        self._registry_file = paths.state_dir / REGISTRY
        self._registry = self._load_registry()

    def write_output(self, path: Path, text: str) -> str:
        """Return "unchanged", "created" or "updated"."""
        current = path.read_text() if path.exists() else None
        if current == text:
            return "unchanged"
        # A file we did not write (or that was edited by hand) is backed up first.
        if current is not None and self._registry.get(str(path)) != _digest(current):
            self._backup(path)
        if not self.dry_run:
            write_atomic(path, text)
            self._registry[str(path)] = _digest(text)
        return "created" if current is None else "updated"

    def ensure_include(self, name: str, include: Include) -> str:
        """Return "unchanged", "added", "updated" or "missing" (no app config)."""
        exists = include.into.exists()
        if not exists and not include.create:
            return "missing"
        text = include.into.read_text() if exists else ""
        block = include_block(name, include)
        begin = re.escape(block.splitlines()[0])
        end = re.escape(block.splitlines()[-1])
        found = re.search(rf"^{begin}\n.*?^{end}\n?", text, flags=re.MULTILINE | re.DOTALL)
        if found:
            new_text = text[:found.start()] + block + text[found.end():]
        elif include.position == "start":
            new_text = block + ("\n" + text if text else "")
        else:
            new_text = text + ("" if not text or text.endswith("\n") else "\n") + ("\n" if text else "") + block
        if new_text == text:
            return "unchanged"
        if exists:
            self._backup(include.into)
        if not self.dry_run:
            write_atomic(include.into, new_text)
        return "updated" if found else "added"

    def save(self) -> None:
        if not self.dry_run:
            write_atomic(self._registry_file, json.dumps(self._registry, indent=2, sort_keys=True) + "\n")

    def _backup(self, path: Path) -> None:
        target = self.backup_dir / str(path).lstrip("/")
        if self.dry_run or target.exists():
            return
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(path, target)
        self.backups.append(target)

    def _load_registry(self) -> dict[str, str]:
        try:
            data = json.loads(self._registry_file.read_text())
        except (OSError, json.JSONDecodeError):
            return {}
        return data if isinstance(data, dict) else {}


def _digest(text: str) -> str:
    return hashlib.sha256(text.encode()).hexdigest()
