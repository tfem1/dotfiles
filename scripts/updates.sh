#!/usr/bin/env bash
# Package updates, for the bar's update icon.
# Usage: updates.sh count    how many packages can be updated (0 if unknown)
#        updates.sh install  update them (asks for your password), then tell
#                            the shell to count again
# Arch: checkupdates (pacman-contrib: it syncs a copy of the database, never
# the system's); Debian: apt's last package lists; Fedora: dnf check-update.
set -uo pipefail

shell="${TFEM_SHELL:-desktop}"

count() {
  if command -v checkupdates >/dev/null 2>&1; then
    checkupdates 2>/dev/null | grep -c . || true
  elif command -v apt >/dev/null 2>&1; then
    apt list --upgradable 2>/dev/null | grep -c "upgradable from" || true
  elif command -v dnf >/dev/null 2>&1; then
    # Exit code 100: updates are listed, one package per line until a blank line.
    dnf check-update -q 2>/dev/null | awk 'NF == 0 { exit } NF >= 3 { n++ } END { print n + 0 }'
  else
    echo 0
  fi
}

install() {
  if command -v pacman >/dev/null 2>&1; then
    sudo pacman -Syu
  elif command -v apt >/dev/null 2>&1; then
    sudo apt update && sudo apt upgrade
  elif command -v dnf >/dev/null 2>&1; then
    sudo dnf upgrade
  else
    echo "updates: no known package manager (pacman, apt, dnf)" >&2
    return 1
  fi
}

case "${1:-}" in
  count) count ;;
  install)
    install
    status=$?
    qs ipc -c "$shell" call updates refresh >/dev/null 2>&1 || true
    read -r -p "Done. Press Enter to close." _ || true
    exit "$status"
    ;;
  *) echo "usage: updates.sh count|install" >&2; exit 64 ;;
esac
