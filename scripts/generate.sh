#!/usr/bin/env bash
# Renders theme files from theme.toml (format: docs/templates.md).
# This script only checks Python, then hands over to scripts/theming.
set -euo pipefail

root="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/.." && pwd)"

if ! command -v python3 >/dev/null 2>&1; then
  echo "error: python3 is required" >&2
  exit 1
fi

if ! python3 -c 'import sys; sys.exit(sys.version_info < (3, 11))'; then
  echo "error: python 3.11 or newer is required (found $(python3 -V 2>&1))" >&2
  exit 1
fi

PYTHONPATH="$root/scripts" exec python3 -m theming --root "$root" "$@"
