#!/bin/bash
set -euo pipefail

SETTINGS="$HOME/.config/noctalia/settings.json"

# Function to get wallpaper path from settings.json
get_wallpaper_path() {
	if command -v jq >/dev/null && [[ -f "$SETTINGS" ]]; then
		jq -r '.wallpaper.monitors[0].wallpaper // .wallpaper.defaultWallpaper // empty' "$SETTINGS"
	fi
}

# Wait for settings.json to be updated using inotifywait (more efficient than polling)
if command -v inotifywait >/dev/null 2>&1; then
	# Use inotifywait to wait for file close (write complete) with 1 second timeout
	inotifywait -e close_write -t 1 "$SETTINGS" >/dev/null 2>&1 || true
	# Give it a tiny moment to ensure JSON is fully written
	sleep 0.05
else
	# Fallback: wait for file modification time to change
	OLD_MTIME=$(stat -c %Y "$SETTINGS" 2>/dev/null || echo 0)
	for i in {1..20}; do
		sleep 0.05
		NEW_MTIME=$(stat -c %Y "$SETTINGS" 2>/dev/null || echo 0)
		if [[ "$NEW_MTIME" != "$OLD_MTIME" ]]; then
			sleep 0.05  # Small delay to ensure write is complete
			break
		fi
	done
fi

# Get the wallpaper path after the file has been updated
WALLPAPER_PATH=$(get_wallpaper_path)

# Call waypaper with the wallpaper path
# This will trigger waypaper's automation which calls wallcache.sh
if [[ -n "$WALLPAPER_PATH" && -f "$WALLPAPER_PATH" ]]; then
	waypaper --wallpaper "$WALLPAPER_PATH"
fi

