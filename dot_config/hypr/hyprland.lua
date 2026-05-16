-- ~/.config/hypr/hyprland.lua
-- Migrated from legacy .conf files to Lua syntax (Hyprland 0.55+)

------------------
---- VARIABLES ----
------------------

local scrPath   = os.getenv("HOME") .. "/.local/scripts"
local cachePath = os.getenv("HOME") .. "/.cache/"
local mainMod   = "SUPER"
local term      = "ghostty"
local editor    = "cursor"
local file      = "dolphin"
local browser   = "zen-browser"

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

-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

-- Script Path
hl.env("PATH", os.getenv("PATH") .. ":" .. scrPath)
hl.env("TERM", "ghostty")
hl.env("EDITOR", "nvim")

-- Input method (fcitx5)
hl.env("GTK_IM_MODULE", "fcitx")
hl.env("QT_IM_MODULE", "fcitx")
hl.env("XMODIFIERS", "@im=fcitx")
hl.env("SDL_IM_MODULE", "fcitx")

-- Nvidia
hl.env("GBM_BACKEND", "nvidia-drm")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
hl.env("LIBVA_DRIVER_NAME", "nvidia")

-- XDG
hl.env("XDG_MENU_PREFIX", "arch-")
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")

-- Wayland compatibility
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")
hl.env("MOZ_ENABLE_WAYLAND", "1")

-- Qt
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("QT_STYLE_OVERRIDE", "kvantum")

-----------------------
---- LOOK AND FEEL ----
-----------------------

hl.config({
    decoration = {
        active_opacity = 0.95,
        inactive_opacity = 0.85,
        fullscreen_opacity = 1.0,
        rounding = 4,
        blur = {
            enabled = true,
            xray = true,
            special = false,
            new_optimizations = true,
            size = 6,
            passes = 3,
            ignore_opacity = true,
            noise = 0.01,
            contrast = 1,
            popups = true,
            popups_ignorealpha = 0.6,
        },
    },
})

hl.config({
    general = {
        gaps_in = 3,
        gaps_out = 5,
        border_size = 3,
        col = {
            active_border = {
                colors = { "rgba(cba6f7ee)", "rgba(f5e0dcee)" },
                angle = 45,
            },
            inactive_border = "rgba(45475aee)",
        },
        layout = "scrolling",
    },
})

hl.config({
    input = {
        kb_layout = "us",
        kb_variant = "",
        kb_model = "",
        kb_options = "",
        kb_rules = "",
        follow_mouse = 1,
        float_switch_override_focus = 2,
        touchpad = {
            natural_scroll = true,
        },
        sensitivity = 0,
    },
})

hl.config({
    scrolling = {
        fullscreen_on_one_column = true,
        column_width = 0.5,
        focus_fit_method = 1,
        follow_focus = true,
        follow_min_visible = 0.4,
        explicit_column_widths = "0.333, 0.5, 0.667, 1.0",
        wrap_focus = true,
        wrap_swapcol = true,
        direction = "right",
    },
})

hl.config({
    master = {
        new_status = "master",
        special_scale_factor = 0.8,
    },
})

hl.config({
    misc = {
        disable_hyprland_logo = true,
        always_follow_on_dnd = true,
        layers_hog_keyboard_focus = true,
        animate_manual_resizes = false,
        enable_swallow = true,
        swallow_regex = "",
        focus_on_activate = true,
        vrr = 0,
    },
})

hl.config({
    debug = {
        disable_logs = false,
    },
})

hl.config({
    binds = {
        workspace_back_and_forth = true,
        allow_workspace_cycles = true,
    },
})

------------------
---- ANIMATIONS ----
------------------

hl.config({
    animations = {
        enabled = true,
    },
})

hl.curve("myBezier", { type = "bezier", points = { {0.05, 0.9}, {0.1, 1.05} } })

hl.animation({ leaf = "windows",    enabled = true, speed = 7,  bezier = "myBezier" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 7,  bezier = "default", style = "popin 80%" })
hl.animation({ leaf = "border",     enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "borderangle", enabled = true, speed = 8,  bezier = "default" })
hl.animation({ leaf = "fade",       enabled = true, speed = 7,  bezier = "default" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 6,  bezier = "default" })

------------------
---- GESTURES ----
------------------

hl.gesture({ fingers = 3, direction = "left",  action = "workspace" })
hl.gesture({ fingers = 3, direction = "right", action = "workspace" })
hl.gesture({ fingers = 3, direction = "up",    action = "special", workspace_name = "overview" })
hl.gesture({ fingers = 3, direction = "down",  action = "fullscreen" })
hl.gesture({ fingers = 2, direction = "left",  action = "move" })
hl.gesture({ fingers = 2, direction = "right", action = "move" })
hl.gesture({ fingers = 2, direction = "up",    action = "resize" })
hl.gesture({ fingers = 2, direction = "down",  action = "resize" })

------------------
---- DEVICE ----
------------------

hl.device({ name = "epic-mouse-v1", sensitivity = -0.5 })

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
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("qs -c noctalia-shell ipc call volume increase"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("qs -c noctalia-shell ipc call volume decrease"), { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("qs -c noctalia-shell ipc call volume muteOutput"), { locked = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("qs -c noctalia-shell ipc call volume muteInput"), { locked = true })

-- 5. Brightness
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("qs -c noctalia-shell ipc call brightness increase"),  { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("qs -c noctalia-shell ipc call brightness decrease"), { locked = true, repeating = true })

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
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "-1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "+1" }))

for i = 1, 9 do
    hl.bind(mainMod .. " + " .. i,         hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + CTRL + " .. i,  hl.dsp.window.move({ workspace = i }))
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
hl.bind(mainMod .. " + minus",       hl.dsp.layout("colresize -0.1"),  { repeating = true })
hl.bind(mainMod .. " + equal",       hl.dsp.layout("colresize +0.1"),  { repeating = true })
hl.bind(mainMod .. " + SHIFT + minus", hl.dsp.layout("colresize -conf"), { repeating = true })
hl.bind(mainMod .. " + SHIFT + equal", hl.dsp.layout("colresize +conf"), { repeating = true })

-- 15. Scrolling column management (niri-style)
hl.bind(mainMod .. " + bracketleft",  hl.dsp.layout("consume_or_expel prev"))
hl.bind(mainMod .. " + bracketright", hl.dsp.layout("consume_or_expel next"))
hl.bind(mainMod .. " + R",            hl.dsp.layout("colresize +conf"))
hl.bind(mainMod .. " + SHIFT + R",    hl.dsp.layout("colresize -conf"))
hl.bind(mainMod .. " + CTRL + F",     hl.dsp.layout("fit active"))
hl.bind(mainMod .. " + SHIFT + I",    hl.dsp.layout("inhibit_scroll"))

-- 16. Mouse
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

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
hl.window_rule({ name = "steam-opacity-70",            match = { class = "^([Ss]team)$" },            opacity = "0.70 0.70" })
hl.window_rule({ name = "steamwebhelper-opacity-70",   match = { class = "^(steamwebhelper)$" },      opacity = "0.70 0.70" })
hl.window_rule({ name = "spotify-opacity-70",          match = { class = "^(Spotify)$" },             opacity = "0.70 0.70" })
hl.window_rule({ name = "spotify-free-opacity-70",     match = { initial_title = "^(Spotify Free)$" },     opacity = "0.70 0.70" })
hl.window_rule({ name = "spotify-premium-opacity-70",  match = { initial_title = "^(Spotify Premium)$" },  opacity = "0.70 0.70" })

-- Opacity 0.95 0.95 (by title)
hl.window_rule({ name = "telegram-opacity-95",         match = { title = "^(Telegram)$" },                   opacity = "0.95 0.95" })
hl.window_rule({ name = "qq-opacity-95",               match = { title = "^(QQ)$" },                         opacity = "0.95 0.95" })
hl.window_rule({ name = "netease-opacity-95",          match = { title = "^(NetEase Cloud Music Gtk4)$" },   opacity = "0.95 0.95" })

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
}
for _, app in ipairs(float_apps) do
    hl.window_rule({ name = app .. "-float", match = { class = "^(" .. app .. ")$" }, float = true })
end

-- Float rules (title-only)
hl.window_rule({ name = "rog-float",                match = { title = "^(ROG)$" },                       float = true })
hl.window_rule({ name = "pip-float-1",              match = { title = "^(Picture in picture)$" },        float = true })
hl.window_rule({ name = "steam-updater-float",      match = { title = "^(Steam - Self Updater)$" },      float = true })
hl.window_rule({ name = "about-firefox-float",      match = { title = "^(About Mozilla Firefox)$" },     float = true })
hl.window_rule({ name = "pip-float-2",              match = { title = "^(Picture-in-Picture)$" },        float = true })
hl.window_rule({ name = "rog-control-float",        match = { title = "^(ROG Control)$" },               float = true })

-- Float rules (class + title)
hl.window_rule({ name = "brave-save-float",              match = { class = "^(brave)$", title = "^(Save File)$" },                  float = true })
hl.window_rule({ name = "brave-open-float",              match = { class = "^(brave)$", title = "^(Open File)$" },                  float = true })
hl.window_rule({ name = "librewolf-pip-float",           match = { class = "^(LibreWolf)$", title = "^(Picture-in-Picture)$" },     float = true })
hl.window_rule({ name = "dolphin-progress-float",        match = { class = "^(org.kde.dolphin)$", title = "^(Progress Dialog — Dolphin)$" }, float = true })
hl.window_rule({ name = "dolphin-copying-float",         match = { class = "^(org.kde.dolphin)$", title = "^(Copying — Dolphin)$" },         float = true })
hl.window_rule({ name = "firefox-pip-float",             match = { class = "^(firefox)$", title = "^(Picture-in-Picture)$" },       float = true })
hl.window_rule({ name = "firefox-library-float",         match = { class = "^(firefox)$", title = "^(Library)$" },                  float = true })
hl.window_rule({ name = "kitty-top-float",               match = { class = "^(kitty)$", title = "^(top)$" },                        float = true })
hl.window_rule({ name = "kitty-btop-float",              match = { class = "^(kitty)$", title = "^(btop)$" },                       float = true })
hl.window_rule({ name = "kitty-htop-float",              match = { class = "^(kitty)$", title = "^(htop)$" },                       float = true })
hl.window_rule({ name = "ghostty-top-float",             match = { class = "^(com.mitchellh.ghostty)$", title = "^(top)$" },        float = true })
hl.window_rule({ name = "ghostty-btop-float",            match = { class = "^(com.mitchellh.ghostty)$", title = "^(btop)$" },       float = true })
hl.window_rule({ name = "ghostty-htop-float",            match = { class = "^(com.mitchellh.ghostty)$", title = "^(htop)$" },       float = true })

-- imv rules
hl.window_rule({ name = "imv-float",    match = { class = "^(imv)$" },    float = true })
hl.window_rule({ name = "imv-move",     match = { class = "^(imv)$" },    move = "(monitor_w*0.75) (monitor_h*0.5)" })
hl.window_rule({ name = "imv-size",     match = { class = "^(imv)$" },    size = "960 540" })

-- mpv rules
hl.window_rule({ name = "mpv-float",    match = { class = "^(mpv)$" },    float = true })
hl.window_rule({ name = "mpv-move",     match = { class = "^(mpv)$" },    move = "(monitor_w*0.75) (monitor_h*0.5)" })
hl.window_rule({ name = "mpv-size",     match = { class = "^(mpv)$" },    size = "960 540" })

-- danmufloat rules
hl.window_rule({ name = "danmufloat-float",    match = { class = "^(danmufloat)$" }, float = true })
hl.window_rule({ name = "danmufloat-move",     match = { class = "^(danmufloat)$" }, move = "(monitor_w*0.75) (monitor_h*0.5)" })
hl.window_rule({ name = "danmufloat-pin",      match = { class = "^(danmufloat)$" }, pin = true })
hl.window_rule({ name = "danmufloat-rounding", match = { class = "^(danmufloat)$" }, rounding = 5 })
hl.window_rule({ name = "danmufloat-size",     match = { class = "^(danmufloat)$" }, size = "960 540" })

-- termfloat rules
hl.window_rule({ name = "termfloat-float",    match = { class = "^(termfloat)$" }, float = true })
hl.window_rule({ name = "termfloat-move",     match = { class = "^(termfloat)$" }, move = "(monitor_w*0.75) (monitor_h*0.5)" })
hl.window_rule({ name = "termfloat-size",     match = { class = "^(termfloat)$" }, size = "960 540" })
hl.window_rule({ name = "termfloat-rounding", match = { class = "^(termfloat)$" }, rounding = 5 })

-- nemo rules
hl.window_rule({ name = "nemo-float", match = { class = "^(nemo)$" }, float = true })
hl.window_rule({ name = "nemo-move",  match = { class = "^(nemo)$" }, move = "(monitor_w*0.75) (monitor_h*0.5)" })
hl.window_rule({ name = "nemo-size",  match = { class = "^(nemo)$" }, size = "960 540" })

-- Terminal animation rules
hl.window_rule({ name = "kitty-animation",     match = { class = "^(kitty)$" },                    animation = "slide right" })
hl.window_rule({ name = "ghostty-animation",   match = { class = "^(com.mitchellh.ghostty)$" },    animation = "slide right" })
hl.window_rule({ name = "alacritty-animation", match = { class = "^(alacritty)$" },                animation = "slide right" })

-- ncmpcpp rules
hl.window_rule({ name = "ncmpcpp-float", match = { class = "^(ncmpcpp)$" }, float = true })
hl.window_rule({ name = "ncmpcpp-move",  match = { class = "^(ncmpcpp)$" }, move = "(monitor_w*0.75) (monitor_h*0.5)" })
hl.window_rule({ name = "ncmpcpp-size",  match = { class = "^(ncmpcpp)$" }, size = "960 540" })

-- Picture-in-Picture size / move (title-based)
hl.window_rule({ name = "pip-size-2", match = { title = "^(Picture-in-Picture)$" }, size = "960 540" })
hl.window_rule({ name = "pip-move-2", match = { title = "^(Picture-in-Picture)$" }, move = "(monitor_w*0.75) (monitor_h*0.5)" })

------------------
---- LAYER RULES ----
------------------

hl.layer_rule({ name = "rofi-blur",              match = { namespace = "rofi" },                        blur = true })
hl.layer_rule({ name = "notifications-blur",     match = { namespace = "notifications" },               blur = true })
hl.layer_rule({ name = "swaync-notif-blur",      match = { namespace = "swaync-notification-window" },  blur = true })
hl.layer_rule({ name = "swaync-control-blur",    match = { namespace = "swaync-control-center" },       blur = true })
hl.layer_rule({ name = "logout-dialog-blur",     match = { namespace = "logout_dialog" },               blur = true })
hl.layer_rule({ name = "hyprpicker-no-anim",     match = { namespace = "hyprpicker" },                  no_anim = true })
hl.layer_rule({ name = "gtk-layer-shell-blur",   match = { namespace = "gtk-layer-shell" },             blur = true })

hl.layer_rule({
    name = "noctalia",
    match = { namespace = "noctalia-background-.*$" },
    ignore_alpha = 0.6,
    blur = true,
    blur_popups = true,
})

hl.layer_rule({
    name = "vicinae-blur",
    match = { namespace = "vicinae" },
    blur = true,
    ignore_alpha = 0,
})

hl.layer_rule({
    name = "vicinae-no-animation",
    match = { namespace = "vicinae" },
    no_anim = true,
})
