-- ~/.config/hypr/lua/monitors.lua

return function(ctx)
------------------
---- MONITORS ----
------------------

-- Fallback for any monitor
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })

-- Primary and secondary displays
-- hl.monitor({ output = "DP-1", mode = "2560x1440", position = "0x0", scale = 1 })
-- hl.monitor({ output = "DP-2", mode = "1920x1080", position = "320x-1080", scale = 1 })
hl.monitor({ output = "DP-1", mode = "highres@highrr", position = "0x0", scale = 1 })
hl.monitor({ output = "DP-2", mode = "highres@highrr", position = "320x-1080", scale = 1 })
end
