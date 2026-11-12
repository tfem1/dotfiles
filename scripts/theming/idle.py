"""hypridle listeners from config.json: idle.dim, idle.lock, idle.screen_off
and idle.suspend, in minutes, 0 = never. The commands are those of the
Hyprland wiki's hypridle example, with the 0.57 Lua dispatchers; the
screens go off and on with the commands of the compositor in use."""
from __future__ import annotations

from typing import Mapping

# Screens off and on again, under the compositor in use (its socket says
# which): Niri, Sway, else Hyprland. Niri turns them on by itself at input.
DPMS_ON = ('[ -n "$NIRI_SOCKET" ] || { [ -n "$SWAYSOCK" ] && swaymsg "output * power on"; } '
           "|| hyprctl dispatch 'hl.dsp.dpms({ action = \"enable\" })'")
DPMS_OFF = ('if [ -n "$NIRI_SOCKET" ]; then niri msg action power-off-monitors; '
            'elif [ -n "$SWAYSOCK" ]; then swaymsg "output * power off"; '
            "else hyprctl dispatch 'hl.dsp.dpms({ action = \"disable\" })'; fi")
# key -> (what it does, on-timeout, on-resume or "")
STEPS = {
    "idle.dim": ("dim the screen", "brightnessctl -s set 10", "brightnessctl -r"),
    "idle.lock": ("lock", "loginctl lock-session", ""),
    "idle.screen_off": ("screen off", DPMS_OFF, f"{DPMS_ON} && brightnessctl -r"),
    "idle.suspend": ("suspend", "systemctl suspend", ""),
}


def listeners(config: Mapping[str, object]) -> str:
    """One listener block per step that is not 0 ("never")."""
    blocks = []
    for key, (what, on_timeout, on_resume) in STEPS.items():
        minutes = int(config.get(key, 0) or 0)
        if minutes <= 0:
            blocks.append(f"# {what}: never (idle.{key.split('.')[1]} = 0)")
            continue
        lines = ["listener {", f"    timeout = {minutes * 60}  # {minutes} min: {what}",
                 f"    on-timeout = {on_timeout}"]
        if on_resume:
            lines.append(f"    on-resume = {on_resume}")
        lines.append("}")
        blocks.append("\n".join(lines))
    return "\n\n".join(blocks)
