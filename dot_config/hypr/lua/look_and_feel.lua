-- ~/.config/hypr/lua/look_and_feel.lua

return function(ctx)
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
end
