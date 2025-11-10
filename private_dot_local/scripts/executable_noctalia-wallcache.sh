#!/bin/bash
set -euo pipefail

CACHE_DIR="$HOME/.cache"
SETTINGS="$HOME/.config/noctalia/settings.json"
LAST_PATH_FILE="$CACHE_DIR/wall.last"
LOG_FILE="$CACHE_DIR/noctalia-wallcache.log"
BACKDROP_SCRIPT="$HOME/.config/niri/scripts/niri-backdrop.sh"

mkdir -p "$CACHE_DIR"
exec >>"$LOG_FILE" 2>&1
echo "---- $(date) ----"

REQUEST_PATH="${1:-}"
SCREEN_NAME="${2:-All}"
LAST_PATH="$(cat "$LAST_PATH_FILE" 2>/dev/null || true)"

wait_for_file() {
	local path=$1
	for _ in {1..50}; do
		[[ -f "$path" ]] && { printf '%s' "$path"; return 0; }
		sleep 0.1
	done
	return 1
}

list_candidates() {
	local screen=$1
	if ! command -v jq >/dev/null || [[ ! -f "$SETTINGS" ]]; then
		return 0
	fi

	if [[ "$screen" != "All" ]]; then
		jq -r --arg name "$screen" '.wallpaper.monitors[]? | select(.name == $name) | .wallpaper // empty' "$SETTINGS"
	fi

	jq -r '.wallpaper.monitors[]?.wallpaper // empty' "$SETTINGS"
	jq -r '.wallpaper.defaultWallpaper // empty' "$SETTINGS"
}

pick_wallpaper() {
	local candidate
	while IFS= read -r candidate; do
		[[ -z "$candidate" ]] && continue
		[[ "$candidate" == "$LAST_PATH" ]] && continue
		if [[ -f "$candidate" ]]; then
			printf '%s' "$candidate"
			return 0
		fi
	done
	return 1
}

wallpaper_path=""

if [[ -n "$REQUEST_PATH" ]]; then
	wallpaper_path="$(wait_for_file "$REQUEST_PATH" || true)"
fi

if [[ -z "$wallpaper_path" ]]; then
	if command -v inotifywait >/dev/null && [[ -f "$SETTINGS" ]]; then
		inotifywait -q -t 1 -e close_write "$SETTINGS" || true
	else
		sleep 0.1
	fi
	wallpaper_path="$(pick_wallpaper < <(list_candidates "$SCREEN_NAME") || true)"
fi

if [[ -z "$wallpaper_path" || ! -f "$wallpaper_path" ]]; then
	echo "No valid wallpaper path found; exiting."
	exit 0
fi

echo "Selected wallpaper: ${wallpaper_path} (screen=${SCREEN_NAME})"

cp "$wallpaper_path" "$CACHE_DIR/wall.set"
printf '%s' "$wallpaper_path" >"$LAST_PATH_FILE"

if command -v magick >/dev/null; then
	magick "$wallpaper_path" -blur 0x25 "$CACHE_DIR/wall.blur"
elif command -v convert >/dev/null; then
	convert "$wallpaper_path" -blur 0x25 "$CACHE_DIR/wall.blur"
else
	echo "ImageMagick not found (magick/convert). Skipping blur."
fi

if pgrep -x "niri" >/dev/null && [[ -f "$CACHE_DIR/wall.blur" ]] && [[ -x "$BACKDROP_SCRIPT" ]]; then
	"$BACKDROP_SCRIPT" "$SCREEN_NAME" &
fi
