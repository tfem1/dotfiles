#!/usr/bin/env bash
# Screenshots with grim and slurp: a region or the whole screen, saved to
# ~/Pictures/Screenshots and copied to the clipboard. With --edit, the capture
# opens in satty first and is saved from there.
set -euo pipefail

usage() {
  echo "usage: screenshot.sh region|full [--edit]" >&2
  exit 64
}

mode="${1:-}"
edit="${2:-}"
[[ $mode == region || $mode == full ]] || usage
[[ -z $edit || $edit == --edit ]] || usage

folder="${XDG_PICTURES_DIR:-$HOME/Pictures}/Screenshots"
mkdir -p "$folder"
file="$folder/$(date +%Y-%m-%d_%H-%M-%S).png"

geometry=()
if [[ $mode == region ]]; then
  # Escape in slurp cancels the selection: nothing to do then.
  region="$(slurp)" || exit 0
  geometry=(-g "$region")
fi

if [[ $edit == --edit ]] && ! command -v satty >/dev/null 2>&1; then
  # satty is only packaged on Arch: elsewhere, keep the capture unedited.
  echo "satty is not installed: saving the screenshot without editing" >&2
  edit=""
fi

if [[ $edit == --edit ]]; then
  grim "${geometry[@]}" - | satty --filename - --output-filename "$file"
else
  grim "${geometry[@]}" "$file"
  wl-copy --type image/png < "$file"
fi
