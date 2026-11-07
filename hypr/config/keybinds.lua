-- Every shortcut, with a description (shown by the keybind cheatsheet).
-- Same key layout as Serpantinum; shell panels are opened through
-- Quickshell IPC, the rest uses Hyprland dispatchers and standard tools.

local mod = _G.mainMod or "SUPER"
local shell = _G.shellName or "desktop"

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

local directions = {
  Left = { "left", "l", -50, 0 },
  Right = { "right", "r", 50, 0 },
  Up = { "up", "u", 0, -50 },
  Down = { "down", "d", 0, 50 },
}
for key, d in pairs(directions) do
  bind(mod .. " + " .. key, hl.dsp.focus({ direction = d[1] }), "Focus the window " .. d[1])
  bind(mod .. " + CTRL + " .. key, hl.dsp.window.move({ direction = d[2] }), "Move the window " .. d[1])
  bind(mod .. " + SHIFT + " .. key, hl.dsp.window.resize({ x = d[3], y = d[4], relative = true }),
    "Resize the window towards " .. d[1], { repeating = true })
end

-- Workspaces: keys 1 to 9, then 0 for workspace 10 --------------------------
for i = 1, 10 do
  local key = tostring(i % 10)
  bind(mod .. " + " .. key, hl.dsp.focus({ workspace = i }), "Go to workspace " .. i)
  bind(mod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }), "Send the window to workspace " .. i)
end

-- Shell panels --------------------------------------------------------------
panel("launcher", "Open the launcher")(mod .. " + D")
panel("system", "Open the system panel")(mod .. " + B")
panel("music", "Open the music panel")(mod .. " + M")
panel("wallpaper", "Open the wallpaper selector")(mod .. " + W")
panel("calendar", "Open the calendar")(mod .. " + S")
panel("network", "Open the network panel")(mod .. " + N")
panel("volume", "Open the volume panel")(mod .. " + V")
panel("clipboard", "Open the clipboard history")(mod .. " + C")
panel("settings", "Open the settings")(mod .. " + H")
panel("cheatsheet", "Show the keybind cheatsheet")(mod .. " + slash")
run("qs ipc -c " .. shell .. " call bar toggleAutohide", "Toggle bar autohide")(mod .. " + A")
run("qs kill -c " .. shell .. "; qs -c " .. shell .. " -n -d", "Restart the shell")(mod .. " + R")

-- Session -------------------------------------------------------------------
run("pidof hyprlock || hyprlock", "Lock the screen", { locked = true, repeating = true })(mod .. " + L")
run("pidof hyprlock || hyprlock", "Lock the screen", locked)("XF86PowerOff")

-- Media ---------------------------------------------------------------------
run("playerctl play-pause", "Play or pause", locked)(mod .. " + SPACE")
run("playerctl play-pause", "Play or pause", locked)("XF86AudioPlay")
run("playerctl play-pause", "Play or pause", locked)("XF86AudioPause")
run("playerctl previous", "Previous track", locked)("XF86AudioPrev")
run("playerctl next", "Next track", locked)("XF86AudioNext")

-- Volume and brightness (the shell shows the OSD when the value changes) ---
run("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+", "Raise the volume", held)("XF86AudioRaiseVolume")
run("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-", "Lower the volume", held)("XF86AudioLowerVolume")
run("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle", "Mute the sound", locked)("XF86AudioMute")
run("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle", "Mute the microphone", locked)("XF86AudioMicMute")
run("brightnessctl -e4 -n2 set 5%+", "Raise the brightness", held)("XF86MonBrightnessUp")
run("brightnessctl -e4 -n2 set 5%-", "Lower the brightness", held)("XF86MonBrightnessDown")

-- Screenshots (saved in ~/Pictures/Screenshots and copied) -----------------
run("tfem screenshot region", "Screenshot of a region", locked)("Print")
run("tfem screenshot region --edit", "Screenshot of a region, then edit it", locked)("SHIFT + Print")
run("tfem screenshot full", "Screenshot of the whole screen", locked)(mod .. " + Print")
run("tfem screenshot full --edit", "Screenshot of the whole screen, then edit it", locked)(mod .. " + SHIFT + Print")
