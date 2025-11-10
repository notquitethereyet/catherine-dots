#!/bin/bash

# Path to the wallpaper you want to set
WALLPAPER_PATH="$1"

# Cache directory (create it if it doesn't exist)
CACHE_DIR="$HOME/.cache/"
mkdir -p "$CACHE_DIR"

# Define paths for the cached original and blurred images
ORIGINAL_CACHE="${CACHE_DIR}/wall.set"
BLUR_CACHE="${CACHE_DIR}/wall.blur"

# Copy the original wallpaper to the cache, overwriting the old cache
cp "$WALLPAPER_PATH" "$ORIGINAL_CACHE"

# Create a blurred version, overwriting the old blurred cache
# Using "magick" command for ImageMagick 7 to create a blurred version
magick "$WALLPAPER_PATH" -blur 0x25 "$BLUR_CACHE"

# Update niri backdrop when waypaper changes wallpaper (only if niri is running)
# This ensures the overview backdrop updates when waypaper changes the wallpaper
if pgrep -x "niri" > /dev/null && [ -f "$BLUR_CACHE" ]; then
    "$HOME/.config/niri/scripts/niri-backdrop.sh" &
fi
