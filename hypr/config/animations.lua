-- One snappy curve for everything: windows pop in, layers fade, workspaces
-- slide. Animations can be switched off in theme.toml (effects.animations).

hl.curve("snappy", { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.05 } } })

local function animate(leaf, style)
  hl.animation({ leaf = leaf, enabled = true, speed = 5, bezier = "snappy", style = style })
end

animate("windows", "popin 80%")
animate("windowsOut", "popin 80%")
animate("layers", "fade")
animate("layersIn", "fade")
animate("layersOut", "fade")
animate("fade")
animate("workspaces", "slide")
animate("specialWorkspaceIn", "fade")
animate("specialWorkspaceOut", "fade")
