#!/usr/bin/env bash
# Color picker: click a pixel anywhere (slurp -p), its color is copied as
# #RRGGBB (wl-copy) and kept in a short history. Escape cancels.
# Usage: pick.sh          pick a color
#        pick.sh history  the last colors picked, newest first
set -euo pipefail

history="${XDG_STATE_HOME:-$HOME/.local/state}/tfem/colors"

if [[ ${1:-} == history ]]; then
  [[ -f $history ]] && cat "$history"
  exit 0
fi
[[ $# -eq 0 ]] || { echo "usage: pick.sh [history]" >&2; exit 64; }

point="$(slurp -p)" || exit 0
# One pixel at scale 1, as PPM: a short header, then its red, green, blue bytes.
hex="#$(grim -s 1 -g "$point" -t ppm - | tail -c 3 | od -An -tx1 | tr -d ' \n' | tr a-f A-F)"
[[ $hex =~ ^#[0-9A-F]{6}$ ]] || { echo "pick: could not read the color" >&2; exit 1; }

printf '%s' "$hex" | wl-copy
mkdir -p "$(dirname "$history")"
{ echo "$hex"; [[ -f $history ]] && grep -vx "$hex" "$history" || true; } | head -n 20 > "$history.new"
mv "$history.new" "$history"
notify-send -a "Color picker" "$hex copied" "Paste it anywhere; tfem pick history lists the last ones." || true
echo "$hex"
