#!/usr/bin/env sh

# Set original wallpaper for normal workspace using swww
echo "Using swww for normal workspace"
swww init
swww-daemon --format xrgb
sleep 0.5
swww img $HOME/.cache/wall.set

# Set blurred wallpaper for overview backdrop using swaybg
# Kill any existing swaybg instance
pkill -x swaybg 2>/dev/null || true
sleep 0.2

# Start swaybg with blurred wallpaper for the backdrop
# swaybg uses namespace "wallpaper" which matches our layer-rule
if [ -f "$HOME/.cache/wall.blur" ]; then
    echo "Setting blurred backdrop with swaybg"
    swaybg -i "$HOME/.cache/wall.blur" -m fill &
else
    # Fallback to original if blur doesn't exist
    echo "Blurred wallpaper not found, using original for backdrop"
    swaybg -i "$HOME/.cache/wall.set" -m fill &
fi