-- ~/.config/hypr/lua/windowrules.lua

return function(ctx)
--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

-- Opacity 0.90 0.90
local opacity_90_90 = { "firefox", "zen-browser", "Brave-browser", "com.github.rafostar.Clapper" }
for _, app in ipairs(opacity_90_90) do
    hl.window_rule({ name = app .. "-opacity-90", match = { class = "^(" .. app .. ")$" }, opacity = "0.90 0.90" })
end

-- Opacity 0.80 0.80
local opacity_80_80 = {
    "code-oss", "Code", "code-url-handler", "code-insiders-url-handler",
    "kitty", "com.mitchellh.ghostty", "thunar", "org.kde.dolphin", "org.kde.ark",
    "nwg-look", "qt5ct", "qt6ct", "kvantummanager",
    "com.github.tchx84.Flatseal", "hu.kramo.Cartridges", "com.obsproject.Studio",
    "gnome-boxes", "vesktop", "discord", "WebCord", "ArmCord",
    "app.drey.Warp", "net.davidotek.pupgui2", "yad", "Signal",
    "io.github.alainm23.planify", "io.gitlab.theevilskeleton.Upscaler",
    "com.github.unrud.VideoDownloader", "io.gitlab.adhami3310.Impression",
    "io.missioncenter.MissionCenter",
}
for _, app in ipairs(opacity_80_80) do
    hl.window_rule({ name = app .. "-opacity-80", match = { class = "^(" .. app .. ")$" }, opacity = "0.80 0.80" })
end

-- Opacity 0.80 0.70
local opacity_80_70 = {
    "org.pulseaudio.pavucontrol", "blueman-manager", "nm-applet",
    "nm-connection-editor", "org.kde.polkit-kde-authentication-agent-1",
    "polkit-gnome-authentication-agent-1",
    "org.freedesktop.impl.portal.desktop.gtk",
    "org.freedesktop.impl.portal.desktop.hyprland",
}
for _, app in ipairs(opacity_80_70) do
    hl.window_rule({ name = app .. "-opacity-80-70", match = { class = "^(" .. app .. ")$" }, opacity = "0.80 0.70" })
end

-- Opacity 0.70 0.70
hl.window_rule({ name = "steam-opacity-70", match = { class = "^([Ss]team)$" }, opacity = "0.70 0.70" })
hl.window_rule({ name = "steamwebhelper-opacity-70", match = { class = "^(steamwebhelper)$" }, opacity = "0.70 0.70" })
hl.window_rule({ name = "spotify-opacity-70", match = { class = "^(Spotify)$" }, opacity = "0.70 0.70" })
hl.window_rule({ name = "spotify-free-opacity-70", match = { initial_title = "^(Spotify Free)$" }, opacity = "0.70 0.70" })
hl.window_rule({
    name = "spotify-premium-opacity-70",
    match = { initial_title = "^(Spotify Premium)$" },
    opacity =
    "0.70 0.70"
})

-- Opacity 0.95 0.95 (by title)
hl.window_rule({ name = "telegram-opacity-95", match = { title = "^(Telegram)$" }, opacity = "0.95 0.95" })
hl.window_rule({ name = "qq-opacity-95", match = { title = "^(QQ)$" }, opacity = "0.95 0.95" })
hl.window_rule({ name = "netease-opacity-95", match = { title = "^(NetEase Cloud Music Gtk4)$" }, opacity = "0.95 0.95" })

-- Float rules (class-only)
local float_apps = {
    "Rofi", "Calculator", "pavucontrol", "blueman-manager",
    "xdg-desktop-portal-gtk", "xdg-desktop-portal-kde", "xdg-desktop-portal-hyprland",
    "org.kde.polkit-kde-authentication-agent-1", "CachyOSHello", "zenity",
    "vlc", "kvantummanager", "qt5ct", "qt6ct", "nwg-look", "org.kde.ark",
    "org.pulseaudio.pavucontrol", "nm-applet", "nm-connection-editor",
    "Signal", "com.github.rafostar.Clapper", "app.drey.Warp",
    "net.davidotek.pupgui2", "yad", "eog", "io.github.alainm23.planify",
    "io.gitlab.theevilskeleton.Upscaler", "com.github.unrud.VideoDownloader",
    "io.gitlab.adhami3310.Impression", "io.missioncenter.MissionCenter",
    "Emulator",
}
for _, app in ipairs(float_apps) do
    hl.window_rule({ name = app .. "-float", match = { class = "^(" .. app .. ")$" }, float = true })
end

-- Float rules (title-only)
hl.window_rule({ name = "rog-float", match = { title = "^(ROG)$" }, float = true })
hl.window_rule({ name = "pip-float-1", match = { title = "^(Picture in picture)$" }, float = true })
hl.window_rule({ name = "steam-updater-float", match = { title = "^(Steam - Self Updater)$" }, float = true })
hl.window_rule({ name = "about-firefox-float", match = { title = "^(About Mozilla Firefox)$" }, float = true })
hl.window_rule({ name = "pip-float-2", match = { title = "^(Picture-in-Picture)$" }, float = true })
hl.window_rule({ name = "rog-control-float", match = { title = "^(ROG Control)$" }, float = true })
hl.window_rule({ name = "android-emulator-title-float", match = { title = "^(Android Emulator|.* - Android Emulator).*$" }, float = true })

-- Float rules (class + title)
hl.window_rule({ name = "brave-save-float", match = { class = "^(brave)$", title = "^(Save File)$" }, float = true })
hl.window_rule({ name = "brave-open-float", match = { class = "^(brave)$", title = "^(Open File)$" }, float = true })
hl.window_rule({ name = "librewolf-pip-float", match = { class = "^(LibreWolf)$", title = "^(Picture-in-Picture)$" }, float = true })
hl.window_rule({ name = "dolphin-progress-float", match = { class = "^(org.kde.dolphin)$", title = "^(Progress Dialog|File Transfer|Copying|Moving|Deleting|Trash|Extracting|Compressing) — Dolphin$" }, float = true })
hl.window_rule({ name = "firefox-pip-float", match = { class = "^(firefox)$", title = "^(Picture-in-Picture)$" }, float = true })
hl.window_rule({ name = "firefox-library-float", match = { class = "^(firefox)$", title = "^(Library)$" }, float = true })
hl.window_rule({ name = "kitty-top-float", match = { class = "^(kitty)$", title = "^(top)$" }, float = true })
hl.window_rule({ name = "kitty-btop-float", match = { class = "^(kitty)$", title = "^(btop)$" }, float = true })
hl.window_rule({ name = "kitty-htop-float", match = { class = "^(kitty)$", title = "^(htop)$" }, float = true })
hl.window_rule({ name = "ghostty-top-float", match = { class = "^(com.mitchellh.ghostty)$", title = "^(top)$" }, float = true })
hl.window_rule({ name = "ghostty-btop-float", match = { class = "^(com.mitchellh.ghostty)$", title = "^(btop)$" }, float = true })
hl.window_rule({ name = "ghostty-htop-float", match = { class = "^(com.mitchellh.ghostty)$", title = "^(htop)$" }, float = true })

-- imv rules
hl.window_rule({ name = "imv-float", match = { class = "^(imv)$" }, float = true })
hl.window_rule({ name = "imv-move", match = { class = "^(imv)$" }, move = "(monitor_w*0.75) (monitor_h*0.5)" })
hl.window_rule({ name = "imv-size", match = { class = "^(imv)$" }, size = "960 540" })

-- mpv rules
hl.window_rule({ name = "mpv-float", match = { class = "^(mpv)$" }, float = true })
hl.window_rule({ name = "mpv-move", match = { class = "^(mpv)$" }, move = "(monitor_w*0.75) (monitor_h*0.5)" })
hl.window_rule({ name = "mpv-size", match = { class = "^(mpv)$" }, size = "960 540" })

-- danmufloat rules
hl.window_rule({ name = "danmufloat-float", match = { class = "^(danmufloat)$" }, float = true })
hl.window_rule({
    name = "danmufloat-move",
    match = { class = "^(danmufloat)$" },
    move =
    "(monitor_w*0.75) (monitor_h*0.5)"
})
hl.window_rule({ name = "danmufloat-pin", match = { class = "^(danmufloat)$" }, pin = true })
hl.window_rule({ name = "danmufloat-rounding", match = { class = "^(danmufloat)$" }, rounding = 5 })
hl.window_rule({ name = "danmufloat-size", match = { class = "^(danmufloat)$" }, size = "960 540" })

-- termfloat rules
hl.window_rule({ name = "termfloat-float", match = { class = "^(termfloat)$" }, float = true })
hl.window_rule({ name = "termfloat-move", match = { class = "^(termfloat)$" }, move = "(monitor_w*0.75) (monitor_h*0.5)" })
hl.window_rule({ name = "termfloat-size", match = { class = "^(termfloat)$" }, size = "960 540" })
hl.window_rule({ name = "termfloat-rounding", match = { class = "^(termfloat)$" }, rounding = 5 })

-- nemo rules
hl.window_rule({ name = "nemo-float", match = { class = "^(nemo)$" }, float = true })
hl.window_rule({ name = "nemo-move", match = { class = "^(nemo)$" }, move = "(monitor_w*0.75) (monitor_h*0.5)" })
hl.window_rule({ name = "nemo-size", match = { class = "^(nemo)$" }, size = "960 540" })

-- Terminal animation rules
hl.window_rule({ name = "kitty-animation", match = { class = "^(kitty)$" }, animation = "slide right" })
hl.window_rule({ name = "ghostty-animation", match = { class = "^(com.mitchellh.ghostty)$" }, animation = "slide right" })
hl.window_rule({ name = "alacritty-animation", match = { class = "^(alacritty)$" }, animation = "slide right" })

-- ncmpcpp rules
hl.window_rule({ name = "ncmpcpp-float", match = { class = "^(ncmpcpp)$" }, float = true })
hl.window_rule({ name = "ncmpcpp-move", match = { class = "^(ncmpcpp)$" }, move = "(monitor_w*0.75) (monitor_h*0.5)" })
hl.window_rule({ name = "ncmpcpp-size", match = { class = "^(ncmpcpp)$" }, size = "960 540" })

-- Picture-in-Picture size / move (title-based)
hl.window_rule({ name = "pip-size-2", match = { title = "^(Picture-in-Picture)$" }, size = "960 540" })
hl.window_rule({
    name = "pip-move-2",
    match = { title = "^(Picture-in-Picture)$" },
    move =
    "(monitor_w*0.75) (monitor_h*0.5)"
})
end
