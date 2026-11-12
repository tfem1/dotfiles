# Idle: dim, lock, screen off, then suspend (hypridle, started with the
# compositor: Hyprland, Sway or Niri).
# Generated from config.json (idle.*, in minutes, 0 = never): change them
# there or in the Settings window (SUPER + H), not here. "Stay awake" in the
# system panel (SUPER + B) blocks all of it: hypridle respects Wayland idle
# inhibitors (ignore_wayland_inhibit = false, the default).

general {
    lock_cmd = qs ipc -c {{ shell.name }} call lock lock || pidof hyprlock || hyprlock  # the shell's, else hyprlock
    before_sleep_cmd = loginctl lock-session                                 # locked before suspend
    after_sleep_cmd = {{ idle.screen_on }}  # screen on at wake-up
}

{{ idle.listeners }}
