-- ~/.config/hypr/lua/keybindings.lua

return function(ctx)
local scrPath = ctx.scrPath
local mainMod = ctx.mainMod
local editor = ctx.editor
local file = ctx.file
local browser = ctx.browser
---------------------
---- KEYBINDINGS ----
---------------------

-- 1. Overview
hl.bind(mainMod .. " + SHIFT + slash", hl.dsp.exec_cmd('hyprctl notify -1 3000 "rgb(ff6b6b)" "Hotkey Overlay"'))
hl.bind(mainMod .. " + slash", hl.dsp.exec_cmd("qs -c noctalia-shell ipc call plugin:keybind-cheatsheet toggle"))

-- 2. Applications
hl.bind(mainMod .. " + return", hl.dsp.exec_cmd("ghostty +new-window"))
hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd("vicinae toggle"))
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd(browser))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(file))
hl.bind(mainMod .. " + X", hl.dsp.exec_cmd(editor))
hl.bind(mainMod .. " + SHIFT + P", hl.dsp.exec_cmd("hyprpicker -a"))
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd("vicinae vicinae://extensions/vicinae/clipboard/history"))
-- SUPER+comma freed (settings available via bar)
hl.bind(mainMod .. " + N", hl.dsp.exec_cmd("qs -c noctalia-shell ipc call notifications toggleHistory"))

-- 3. Security
hl.bind(mainMod .. " + ALT + L", hl.dsp.exec_cmd("qs -c noctalia-shell ipc call lockScreen lock"))
hl.bind(mainMod .. " + SHIFT + E", hl.dsp.exit())
hl.bind("CONTROL + ALT + Delete", hl.dsp.exec_cmd(scrPath .. "/sysmon.sh"))

-- 4. Audio
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("qs -c noctalia-shell ipc call volume increase"),
    { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("qs -c noctalia-shell ipc call volume decrease"),
    { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("qs -c noctalia-shell ipc call volume muteOutput"), { locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("qs -c noctalia-shell ipc call volume muteInput"), { locked = true })

-- 5. Brightness
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("qs -c noctalia-shell ipc call brightness increase"),
    { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("qs -c noctalia-shell ipc call brightness decrease"),
    { locked = true, repeating = true })

-- 6. Window Management
hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + F", hl.dsp.layout("colresize 1.0"))
hl.bind(mainMod .. " + SHIFT + F", hl.dsp.window.fullscreen())
hl.bind(mainMod .. " + SHIFT + T", hl.dsp.window.float({ action = "toggle" }))

-- 7. Focus (scrolling: left/right = column focus, up/down = within column)
hl.bind("ALT + H", hl.dsp.layout("focus l"))
hl.bind("ALT + L", hl.dsp.layout("focus r"))
hl.bind("ALT + K", hl.dsp.focus({ direction = "u" }))
hl.bind("ALT + J", hl.dsp.focus({ direction = "d" }))

-- 8. Move Window (scrolling: swap columns)
hl.bind(mainMod .. " + CTRL + H", hl.dsp.layout("swapcol l"))
hl.bind(mainMod .. " + CTRL + L", hl.dsp.layout("swapcol r"))

-- 9. Focus Monitor
hl.bind(mainMod .. " + SHIFT + K", hl.dsp.focus({ monitor = "u" }))
hl.bind(mainMod .. " + SHIFT + J", hl.dsp.focus({ monitor = "d" }))

-- 10. Move to Monitor
hl.bind(mainMod .. " + SHIFT + CTRL + H", hl.dsp.window.move({ monitor = "l" }))
hl.bind(mainMod .. " + SHIFT + CTRL + L", hl.dsp.window.move({ monitor = "r" }))
hl.bind(mainMod .. " + SHIFT + CTRL + K", hl.dsp.window.move({ monitor = "u" }))
hl.bind(mainMod .. " + SHIFT + CTRL + J", hl.dsp.window.move({ monitor = "d" }))

-- 11. Workspaces
hl.bind(mainMod .. " + H", hl.dsp.focus({ workspace = "-1" }))
hl.bind(mainMod .. " + L", hl.dsp.focus({ workspace = "+1" }))

for i = 1, 9 do
    hl.bind(mainMod .. " + " .. i, hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + CTRL + " .. i, hl.dsp.window.move({ workspace = i }))
end

-- Relative workspace move (removed: SUPER+CTRL+H/L now used for swapcol)

-- 12. Screenshots
hl.bind(mainMod .. " + SHIFT + 3", hl.dsp.exec_cmd(scrPath .. "/screenshot.sh m"))
hl.bind(mainMod .. " + SHIFT + 4", hl.dsp.exec_cmd(scrPath .. "/screenshot.sh sf"))
hl.bind(mainMod .. " + SHIFT + 5", hl.dsp.exec_cmd(scrPath .. "/screenshot.sh w"))

-- 13. System
hl.bind(mainMod .. " + Escape", hl.dsp.exec_cmd("qs -c noctalia-shell ipc call sessionMenu toggle"))
hl.bind(mainMod .. " + SHIFT + O", hl.dsp.exec_cmd("hyprctl dispatch dpms off"))

-- 14. Resize (scrolling: column width — niri-style)
hl.bind(mainMod .. " + minus", hl.dsp.layout("colresize -0.1"), { repeating = true })
hl.bind(mainMod .. " + equal", hl.dsp.layout("colresize +0.1"), { repeating = true })
hl.bind(mainMod .. " + SHIFT + minus", hl.dsp.layout("colresize -conf"), { repeating = true })
hl.bind(mainMod .. " + SHIFT + equal", hl.dsp.layout("colresize +conf"), { repeating = true })

-- 15. Scrolling column management (niri-style)
hl.bind(mainMod .. " + comma", hl.dsp.layout("move -col"))
hl.bind(mainMod .. " + period", hl.dsp.layout("move +col"))
hl.bind(mainMod .. " + mouse_down", hl.dsp.layout("move -col"))
hl.bind(mainMod .. " + mouse_up", hl.dsp.layout("move +col"))
-- Keep CTRL+scroll after plain SUPER+scroll so the more-specific bind wins.
hl.bind(mainMod .. " + ALT + mouse_down", hl.dsp.focus({ workspace = "-1" }))
hl.bind(mainMod .. " + ALT + mouse_up", hl.dsp.focus({ workspace = "+1" }))
hl.bind(mainMod .. " + bracketleft", hl.dsp.layout("consume_or_expel prev"))
hl.bind(mainMod .. " + bracketright", hl.dsp.layout("consume_or_expel next"))
hl.bind(mainMod .. " + R", hl.dsp.layout("colresize +conf"))
hl.bind(mainMod .. " + SHIFT + R", hl.dsp.layout("colresize -conf"))
hl.bind(mainMod .. " + CTRL + F", hl.dsp.layout("fit active"))
hl.bind(mainMod .. " + SHIFT + I", hl.dsp.layout("inhibit_scroll"))

-- 16. Mouse
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })
end
