-- ~/.config/hypr/lua/layerrules.lua

return function(ctx)
------------------
---- LAYER RULES ----
------------------

hl.layer_rule({ name = "rofi-blur", match = { namespace = "rofi" }, blur = true })
hl.layer_rule({ name = "notifications-blur", match = { namespace = "notifications" }, blur = true })
hl.layer_rule({ name = "swaync-notif-blur", match = { namespace = "swaync-notification-window" }, blur = true })
hl.layer_rule({ name = "swaync-control-blur", match = { namespace = "swaync-control-center" }, blur = true })
hl.layer_rule({ name = "logout-dialog-blur", match = { namespace = "logout_dialog" }, blur = true })
hl.layer_rule({ name = "hyprpicker-no-anim", match = { namespace = "hyprpicker" }, no_anim = true })
hl.layer_rule({ name = "gtk-layer-shell-blur", match = { namespace = "gtk-layer-shell" }, blur = true })

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
end
