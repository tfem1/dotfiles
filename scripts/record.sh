#!/usr/bin/env bash
# Screen recording with wf-recorder: the first call starts, the next one
# stops and saves. Usage: record.sh [full|region] [--audio]
#   full (default): the screen in focus; region: an area picked with slurp;
#   --audio: with the sound of the default input (microphone).
# Videos go to ~/Videos/Screencasts. The shell shows a red dot in the bar
# while it records (`qs ipc call recording ...`).
set -euo pipefail

state="${XDG_RUNTIME_DIR:-/tmp}/tfem-recording.pid"
shell="${TFEM_SHELL:-desktop}"

tell_shell() {
  qs ipc -c "$shell" call recording "$1" >/dev/null 2>&1 || true
}

notify() {
  if command -v notify-send >/dev/null 2>&1; then
    notify-send -a "Screen recording" "$@" || true
  fi
}

# Stop: wf-recorder ends cleanly on SIGINT (as with Ctrl+C) and finishes the file.
if [[ -f $state ]] && kill -0 "$(head -n1 "$state")" 2>/dev/null; then
  pid="$(head -n1 "$state")"
  file="$(sed -n 2p "$state")"
  kill -INT "$pid"
  for _ in $(seq 50); do kill -0 "$pid" 2>/dev/null || break; sleep 0.1; done
  rm -f "$state"
  tell_shell stopped
  notify "Recording saved" "$file"
  exit 0
fi
rm -f "$state"

mode="full" audio=()
for arg in "$@"; do
  case "$arg" in
    full | region) mode="$arg" ;;
    --audio) audio=(--audio) ;;
    *) echo "usage: record.sh [full|region] [--audio]" >&2; exit 64 ;;
  esac
done
command -v wf-recorder >/dev/null 2>&1 || { echo "wf-recorder is not installed" >&2; exit 1; }

# The screen in focus, from the compositor in use (with several screens,
# wf-recorder would otherwise ask which one).
focused_output() {
  if [[ -n ${NIRI_SOCKET:-} ]]; then
    niri msg --json focused-output | python3 -c 'import json, sys; print(json.load(sys.stdin)["name"])'
  elif [[ -n ${SWAYSOCK:-} ]]; then
    swaymsg -t get_outputs -r | python3 -c 'import json, sys; print(next(o["name"] for o in json.load(sys.stdin) if o["focused"]))'
  else
    hyprctl monitors -j | python3 -c 'import json, sys; print(next(m["name"] for m in json.load(sys.stdin) if m["focused"]))'
  fi
}

where=()
if [[ $mode == region ]]; then
  region="$(slurp)" || exit 0   # Escape: nothing recorded
  where=(-g "$region")
elif output="$(focused_output 2>/dev/null)" && [[ -n $output ]]; then
  where=(-o "$output")
fi

folder="${XDG_VIDEOS_DIR:-$HOME/Videos}/Screencasts"
mkdir -p "$folder"
file="$folder/$(date +%Y-%m-%d_%H-%M-%S).mp4"
setsid wf-recorder "${where[@]}" "${audio[@]}" -f "$file" </dev/null >/dev/null 2>&1 &
printf '%s\n%s\n' "$!" "$file" >"$state"
tell_shell started
notify "Recording" "SUPER + ALT + R again to stop"
