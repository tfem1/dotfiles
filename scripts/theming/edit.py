"""Change one key of a settings file (TOML) without touching the rest:
comments, order and the other keys stay as the user wrote them."""
from __future__ import annotations

import json
import re
import tomllib

_TABLE = re.compile(r"^\s*\[([^\[\]]+)\]\s*(#.*)?$")


def set_value(text: str, table: str, key: str, value: str | int | float | bool) -> str:
    """Return `text` with `[table] key = value`, replacing the key if present.
    `table` may be dotted ("palette.overrides"); value: text, number or bool."""
    if isinstance(value, float) and value != value:  # NaN has no TOML form
        raise ValueError(f"invalid value for {table}.{key}")
    # JSON writes strings, numbers and booleans the way TOML reads them.
    line = f"{key} = {json.dumps(value, ensure_ascii=False)}"
    lines = text.splitlines()
    start = next((i for i, row in enumerate(lines) if _table(row) == table), None)
    if start is None:
        new_text = text.rstrip("\n") + ("\n\n" if text.strip() else "") + f"[{table}]\n{line}\n"
    else:
        end = next((i for i in range(start + 1, len(lines)) if _table(lines[i]) is not None), len(lines))
        found = next((i for i in range(start + 1, end) if re.match(rf"\s*{re.escape(key)}\s*=", lines[i])), None)
        if found is None:
            lines.insert(start + 1, line)
        else:
            lines[found] = line
        new_text = "\n".join(lines) + "\n"
    # The result must still be valid TOML and hold the new value.
    found = tomllib.loads(new_text)
    for part in table.split("."):
        found = found.get(part, {}) if isinstance(found, dict) else {}
    if not isinstance(found, dict) or found.get(key) != value or type(found.get(key)) is not type(value):
        raise ValueError(f"could not set {table}.{key}: write it by hand")
    return new_text


def _table(row: str) -> str | None:
    match = _TABLE.match(row)
    return match.group(1).strip() if match else None
