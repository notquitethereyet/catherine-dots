#!/usr/bin/env sh

# Set blurred wallpaper for niri overview backdrop using swaybg
# This script is specifically for niri's overview backdrop

# Kill any existing swaybg instance
pkill -x swaybg 2>/dev/null || true
sleep 0.2

# Start swaybg with blurred wallpaper for the backdrop
# swaybg uses namespace "wallpaper" which matches our layer-rule
if [ -f "$HOME/.cache/wall.blur" ]; then
    echo "Setting blurred backdrop with swaybg (niri overview)"
    nohup swaybg -i "$HOME/.cache/wall.blur" -m fill > /dev/null 2>&1 &
else
    # Fallback to original if blur doesn't exist
    echo "Blurred wallpaper not found, using original for backdrop"
    nohup swaybg -i "$HOME/.cache/wall.set" -m fill > /dev/null 2>&1 &
fi

