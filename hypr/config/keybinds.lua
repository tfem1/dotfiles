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

-- Shell panels, screenshots, recording, color picker: the shortcuts you can
-- change in Settings → Keybinds. Generated from keybinds.toml and config.json
-- (keys.*) into keys.lua; their key is written with SUPER for the main key.
local found, keys = pcall(require, "keys")
for _, k in ipairs(found and type(keys) == "table" and keys or {}) do
  local combo = k.key:gsub("^SUPER", mod)
  bind(combo, hl.dsp.exec_cmd(k.run), k.description, k.locked and locked or nil)
end

-- Fixed shortcuts of the shell ----------------------------------------------
panel("overview", "Workspace overview: every window, drag to move")(mod .. " + Tab")
run("qs kill -c " .. shell .. "; qs -c " .. shell .. " -n -d", "Restart the shell")(mod .. " + R")

-- Session -------------------------------------------------------------------
-- The shell's lock screen; hyprlock when the shell is not running.
local lock = "qs ipc -c " .. shell .. " call lock lock || pidof hyprlock || hyprlock"
run(lock, "Lock the screen", { locked = true, repeating = true })(mod .. " + L")
run(lock, "Lock the screen", locked)("XF86PowerOff")

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

