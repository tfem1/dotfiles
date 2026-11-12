-- Every shortcut, with a description (shown by the keybind cheatsheet).
-- Same key layout as Serpantinum; shell panels are opened through
-- Quickshell IPC, the rest uses Hyprland dispatchers and standard tools.

local mod = _G.mainMod or "SUPER"
local shell = _G.shellName or "desktop"
-- Full path: Hyprland started from a login manager often has no
-- ~/.local/bin in its PATH (exec_cmd runs through sh, so "~" is expanded).
local cli = "~/.local/bin/tfem"

local function bind(keys, action, description, flags)
  local options = { description = description }
  for key, value in pairs(flags or {}) do options[key] = value end
  hl.bind(keys, action, options)
end

local function run(command, description, flags)
  return function(keys) bind(keys, hl.dsp.exec_cmd(command), description, flags) end
end

local function panel(target, description)
  return run("qs ipc -c " .. shell .. " call " .. target .. " toggle", description)
end

local locked = { locked = true }
local held = { locked = true, repeating = true }

-- Apps ----------------------------------------------------------------------
run(_G.terminal or "kitty", "Open the terminal")(mod .. " + RETURN")
run(_G.browser or "firefox", "Open the browser")(mod .. " + F")
run(_G.fileManager or "nautilus", "Open the file manager")(mod .. " + E")

-- Windows -------------------------------------------------------------------
bind(mod .. " + Q", hl.dsp.window.close(), "Close the window")
bind(mod .. " + ALT + F", hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }), "Maximize the window")
bind(mod .. " + SHIFT + F", hl.dsp.window.float({ action = "toggle" }), "Float or tile the window")
bind(mod .. " + mouse:272", hl.dsp.window.drag(), "Drag the window", { mouse = true })
bind(mod .. " + mouse:273", hl.dsp.window.resize(), "Resize the window", { mouse = true })
-- On a touchpad: hold the keys and move the pointer (no click needed).
bind(mod .. " + CTRL_L", hl.dsp.window.drag(), "Drag the window (touchpad)", { mouse = true })
bind(mod .. " + ALT_L", hl.dsp.window.resize(), "Resize the window (touchpad)", { mouse = true })

-- A list, not a table of keys, so the cheatsheet keeps this order. Key names
-- are matched without case by Hyprland ("Left" = "left").
local directions = {
  { "Left", "left", -50, 0 },
  { "Right", "right", 50, 0 },
  { "Up", "up", 0, -50 },
  { "Down", "down", 0, 50 },
}
for _, d in ipairs(directions) do
  local key, direction = d[1], d[2]
  bind(mod .. " + " .. key, hl.dsp.focus({ direction = direction }), "Focus the window " .. direction)
  bind(mod .. " + CTRL + " .. key, hl.dsp.window.move({ direction = direction }), "Move the window " .. direction)
  bind(mod .. " + SHIFT + " .. key, hl.dsp.window.resize({ x = d[3], y = d[4], relative = true }),
    "Resize the window " .. direction, { repeating = true })
end

-- Workspaces: keys 1 to 9, then 0 for workspace 10 --------------------------
for i = 1, 10 do
  local key = tostring(i % 10)
  bind(mod .. " + " .. key, hl.dsp.focus({ workspace = i }), "Go to workspace " .. i)
  bind(mod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }), "Send the window to workspace " .. i)
end

-- Shell panels --------------------------------------------------------------
panel("launcher", "Search and open apps")(mod .. " + D")
panel("overview", "Workspace overview: every window, drag to move")(mod .. " + Tab")
panel("system", "Open the system panel")(mod .. " + B")
panel("music", "Open the music panel")(mod .. " + M")
panel("wallpaper", "Open the wallpaper selector")(mod .. " + W")
panel("calendar", "Open the calendar")(mod .. " + S")
panel("network", "Open the network panel")(mod .. " + N")
panel("volume", "Open the volume panel")(mod .. " + V")
panel("clipboard", "Open the clipboard history")(mod .. " + C")
panel("settings", "Open the settings")(mod .. " + H")
panel("gamemode", "Game mode on or off: more performance for games")(mod .. " + G")
panel("cheatsheet", "Show the keybind cheatsheet")(mod .. " + slash")
run("qs ipc -c " .. shell .. " call bar toggleAutohide", "Toggle bar autohide")(mod .. " + A")
run("qs kill -c " .. shell .. "; qs -c " .. shell .. " -n -d", "Restart the shell")(mod .. " + R")

-- Session -------------------------------------------------------------------
-- The shell's lock screen; hyprlock when the shell is not running.
local lock = "qs ipc -c " .. shell .. " call lock lock || pidof hyprlock || hyprlock"
run(lock, "Lock the screen", { locked = true, repeating = true })(mod .. " + L")
run(lock, "Lock the screen", locked)("XF86PowerOff")
panel("power", "Power menu: lock, log out, suspend, restart, shut down")(mod .. " + Escape")

-- Media ---------------------------------------------------------------------
run("playerctl play-pause", "Play or pause", locked)(mod .. " + SPACE")
run("playerctl play-pause", "Play or pause", locked)("XF86AudioPlay")
run("playerctl play-pause", "Play or pause", locked)("XF86AudioPause")
run("playerctl previous", "Previous track", locked)("XF86AudioPrev")
run("playerctl next", "Next track", locked)("XF86AudioNext")

-- Volume and brightness: the shell shows the OSD (it watches the volume,
-- brightness changes are announced to it).
run("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+", "Raise the volume", held)("XF86AudioRaiseVolume")
run("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-", "Lower the volume", held)("XF86AudioLowerVolume")
run("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle", "Mute the sound", locked)("XF86AudioMute")
run("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle", "Mute the microphone", locked)("XF86AudioMicMute")
local osd = " && qs ipc -c " .. shell .. " call osd brightness"
run("brightnessctl -e4 -n2 set 5%+" .. osd, "Raise the brightness", held)("XF86MonBrightnessUp")
run("brightnessctl -e4 -n2 set 5%-" .. osd, "Lower the brightness", held)("XF86MonBrightnessDown")

-- Screenshots (saved in ~/Pictures/Screenshots and copied) -----------------
run(cli .. " screenshot region", "Screenshot of a region", locked)("Print")
run(cli .. " screenshot region --edit", "Edit a screenshot of a region", locked)("SHIFT + Print")
run(cli .. " screenshot full", "Screenshot of the screen", locked)(mod .. " + Print")
run(cli .. " screenshot full --edit", "Edit a screenshot of the screen", locked)(mod .. " + SHIFT + Print")
-- The whole screen, also for keyboards without Print (it takes the key from
-- apps that use it for "Save as").
run(cli .. " screenshot full", "Screenshot of the screen")("CTRL + SHIFT + S")
run(cli .. " screenshot full", "Screenshot of the screen")(mod .. " + SHIFT + Escape")

-- Color picker: click a pixel, its #RRGGBB is copied.
run(cli .. " pick", "Pick a color on the screen")(mod .. " + SHIFT + C")

-- Screen recording (saved in ~/Videos/Screencasts): again to stop.
run(cli .. " record", "Record the screen (again to stop)")(mod .. " + ALT + R")
