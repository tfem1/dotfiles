#!/usr/bin/env bash
# Génère les fichiers de thème depuis theme.toml (format : docs/templates.md).
# Ce script ne fait que vérifier Python, puis délègue au moteur scripts/theming.
set -euo pipefail

root="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/.." && pwd)"

if ! command -v python3 >/dev/null 2>&1; then
  echo "erreur : python3 est nécessaire" >&2
  exit 1
fi

if ! python3 -c 'import sys; sys.exit(sys.version_info < (3, 11))'; then
  echo "erreur : python 3.11 ou plus récent est nécessaire (trouvé : $(python3 -V 2>&1))" >&2
  exit 1
fi

PYTHONPATH="$root/scripts" exec python3 -m theming --root "$root" "$@"
