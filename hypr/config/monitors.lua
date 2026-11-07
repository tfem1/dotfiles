-- One rule for every screen, including screens plugged in later.
-- "highrr" picks the highest refresh rate each screen supports (it may lower
-- the resolution to reach it). For a fixed setup, add a rule per output:
--   hl.monitor({ output = "DP-1", mode = "2560x1440@165", position = "0x0", scale = 1 })

hl.monitor({ output = "", mode = "highrr", position = "auto", scale = 1 })
