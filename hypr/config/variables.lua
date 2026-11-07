-- Modifier key, default apps and keyboard: the values most people change.
-- Other modules read these globals.

mainMod     = "SUPER"
terminal    = "kitty"
browser     = "firefox"
fileManager = "nautilus"

-- Programs started by Hyprland (the shell too) read the terminal from here:
-- the launcher opens terminal apps (btop, nvim…) in it.
hl.env("TERMINAL", terminal)

-- Layouts are switched with Alt + Shift, e.g. layout = "us,fr".
keyboard = {
  layout  = "us",
  options = "grp:alt_shift_toggle",
}
