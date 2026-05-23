-- ~/.config/hypr/lua/env.lua

return function(ctx)
local scrPath = ctx.scrPath
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
end
