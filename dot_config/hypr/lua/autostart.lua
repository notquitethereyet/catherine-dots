-- ~/.config/hypr/lua/autostart.lua

return function(ctx)
local scrPath = ctx.scrPath
-------------------
---- AUTOSTART ----
-------------------

hl.on("hyprland.start", function()
    -- Slow app launch fix
    hl.exec_cmd("systemctl --user import-environment &")
    hl.exec_cmd("hash dbus-update-activation-environment 2>/dev/null &")
    hl.exec_cmd("dbus-update-activation-environment --systemd &")
    -- Bluetooth systray
    hl.exec_cmd("blueman-applet &")
    -- Desktop portal
    hl.exec_cmd("xdg-desktop-portal-hyprland &")
    -- Launcher / clipboard server
    hl.exec_cmd("vicinae server")
    -- Wallpaper
    hl.exec_cmd(scrPath .. "/wallpaper.sh")
    -- Noctalia shell
    hl.exec_cmd("qs -c noctalia-shell")
    -- System services
    hl.exec_cmd("/usr/lib/mate-polkit/polkit-mate-authentication-agent-1")
    hl.exec_cmd("mako &")
    hl.exec_cmd("fcitx5 -d")
    hl.exec_cmd("nm-applet --indicator &")
    -- Clipboard history
    hl.exec_cmd([[bash -c "wl-paste --watch cliphist store &"]])
end)
end
