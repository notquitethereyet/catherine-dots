-- ~/.config/hypr/lua/gestures.lua

return function(ctx)
------------------
---- GESTURES ----
------------------

hl.gesture({ fingers = 3, direction = "left", action = "workspace" })
hl.gesture({ fingers = 3, direction = "right", action = "workspace" })
hl.gesture({ fingers = 3, direction = "up", action = "special", workspace_name = "overview" })
hl.gesture({ fingers = 3, direction = "down", action = "fullscreen" })
hl.gesture({ fingers = 2, direction = "left", action = "move" })
hl.gesture({ fingers = 2, direction = "right", action = "move" })
hl.gesture({ fingers = 2, direction = "up", action = "resize" })
hl.gesture({ fingers = 2, direction = "down", action = "resize" })
end
