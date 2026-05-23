-- ~/.config/hypr/hyprland.lua
-- Migrated from legacy .conf files to Lua syntax (Hyprland 0.55+)
-- Modularized like the previous .conf setup: variables plus focused config modules.

local configDir = os.getenv("HOME") .. "/.config/hypr"
local moduleDir = configDir .. "/lua"

local ctx = dofile(moduleDir .. "/variables.lua")

local modules = {
    "monitors",
    "autostart",
    "env",
    "look_and_feel",
    "animations",
    "gestures",
    "devices",
    "keybindings",
    "windowrules",
    "layerrules",
}

for _, name in ipairs(modules) do
    dofile(moduleDir .. "/" .. name .. ".lua")(ctx)
end
