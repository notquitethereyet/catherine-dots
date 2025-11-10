#!/usr/bin/env sh

# Detect which compositor is running and logout appropriately

# Check if niri is running
if pgrep -x "niri" > /dev/null; then
    # Logout from niri (shows confirmation dialog)
    niri msg action quit
    exit 0
fi

# Check if hyprland is running
if pgrep -x "Hyprland" > /dev/null; then
    # Logout from hyprland
    hyprctl dispatch exit
    exit 0
fi

# Fallback: if neither compositor is detected, try to logout from the session
# This handles edge cases where the compositor process name might differ
if [ -n "$WAYLAND_DISPLAY" ] || [ -n "$DISPLAY" ]; then
    # Try niri first (most common)
    if command -v niri > /dev/null 2>&1; then
        niri msg action quit 2>/dev/null && exit 0
    fi
    # Try hyprland
    if command -v hyprctl > /dev/null 2>&1; then
        hyprctl dispatch exit 2>/dev/null && exit 0
    fi
fi

# If we get here, something went wrong
echo "Error: Could not detect running compositor (niri or hyprland)" >&2
exit 1

