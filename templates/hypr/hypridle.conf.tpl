# Idle: dim, lock, screen off, then suspend (hypridle, started with Hyprland).
# Generated from config.json (idle.*, in minutes, 0 = never): change them
# there or in the Settings window (SUPER + H), not here. "Stay awake" in the
# system panel (SUPER + B) blocks all of it: hypridle respects Wayland idle
# inhibitors (ignore_wayland_inhibit = false, the default).

general {
    lock_cmd = pidof hyprlock || hyprlock                                    # one lock screen only
    before_sleep_cmd = loginctl lock-session                                 # locked before suspend
    after_sleep_cmd = hyprctl dispatch 'hl.dsp.dpms({ action = "enable" })'  # screen on at wake-up
}

{{ idle.listeners }}
