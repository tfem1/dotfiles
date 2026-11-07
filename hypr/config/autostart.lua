-- Programs started once with Hyprland: clipboard history (text and images)
-- and the Quickshell shell, which hosts the bar, panels and notifications.

local shell = _G.shellName or "desktop"

hl.on("hyprland.start", function()
  hl.exec_cmd("wl-paste --type text --watch cliphist store")
  hl.exec_cmd("wl-paste --type image --watch cliphist store")
  hl.exec_cmd("qs -c " .. shell .. " -n -d")
end)
