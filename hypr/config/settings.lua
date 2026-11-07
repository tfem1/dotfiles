-- Behaviour that does not depend on the theme. Gaps, borders, corners, blur,
-- shadows and fonts live in theme.toml and reach Hyprland through theme.lua.

local keyboard = _G.keyboard or { layout = "us", options = "" }

hl.config({
  general = {
    float_gaps = 6,
    resize_on_border = true,
    extend_border_grab_area = 30,
  },

  decoration = {
    active_opacity = 1.0,
    inactive_opacity = 1.0,
  },

  input = {
    kb_layout = keyboard.layout,
    kb_options = keyboard.options,
    accel_profile = "flat",
    touchpad = {
      natural_scroll = true,
      disable_while_typing = false,
    },
  },

  misc = {
    focus_on_activate = false,
    disable_hyprland_logo = true,
    disable_splash_rendering = true,
  },
})

-- Three fingers left or right: previous or next workspace.
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
