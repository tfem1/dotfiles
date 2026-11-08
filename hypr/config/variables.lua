-- Modifier key, default apps and keyboard: the values most people change.
-- Other modules read these globals.

mainMod     = "SUPER"
terminal    = "kitty"
browser     = "firefox"
fileManager = "nautilus"

-- Programs started by Hyprland (the shell too) read the terminal from here:
-- the launcher opens terminal apps (btop, nvim…) in it.
hl.env("TERMINAL", terminal)
-- Qt apps take the theme colors from qt5ct / qt6ct (both answer to "qt5ct").
hl.env("QT_QPA_PLATFORMTHEME", "qt5ct")

-- The tfem command lives in ~/.local/bin, which many distros (Arch too) leave
-- out of the PATH: put it there for every program Hyprland starts, so that
-- `tfem …` works in the terminal. Read again on reload: added only once.
local home, path = os.getenv("HOME"), os.getenv("PATH") or "/usr/local/bin:/usr/bin:/bin"
if home and not (":" .. path .. ":"):find(":" .. home .. "/.local/bin:", 1, true) then
  hl.env("PATH", home .. "/.local/bin:" .. path)
end

-- Layouts are switched with Alt + Shift, e.g. layout = "us,fr".
keyboard = {
  layout  = "us",
  options = "grp:alt_shift_toggle",
}
