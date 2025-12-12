#!/bin/bash
set -euo pipefail

# Path to colors.json (Noctalia/Matugen generated)
COLORS_JSON="${HOME}/.config/noctalia/colors.json"
THEME_OUTPUT="${HOME}/.config/rofi/theme.rasi"

# Check if colors.json exists
if [[ ! -f "$COLORS_JSON" ]]; then
	echo "Error: colors.json not found at $COLORS_JSON" >&2
	exit 1
fi

# Check if jq is available
if ! command -v jq >/dev/null 2>&1; then
	echo "Error: jq is required but not installed" >&2
	exit 1
fi

# Extract colors from JSON
mSurface=$(jq -r '.mSurface // "#1a1b26"' "$COLORS_JSON")
mOnSurface=$(jq -r '.mOnSurface // "#c0caf5"' "$COLORS_JSON")
mPrimary=$(jq -r '.mPrimary // "#7aa2f7"' "$COLORS_JSON")
mOnPrimary=$(jq -r '.mOnPrimary // "#16161e"' "$COLORS_JSON")
mOnSurfaceVariant=$(jq -r '.mOnSurfaceVariant // "#9aa5ce"' "$COLORS_JSON")
mTertiary=$(jq -r '.mTertiary // "#9ece6a"' "$COLORS_JSON")
mOutline=$(jq -r '.mOutline // "#565f89"' "$COLORS_JSON")

# Convert hex colors to hex with alpha (E6 = ~90% opacity, 80 = ~50% opacity, 40 = ~25% opacity)
# Function to add alpha to hex color
add_alpha() {
	local color=$1
	local alpha=$2
	# Remove # if present
	color=${color#\#}
	# Add alpha
	echo "#${color}${alpha}"
}

# Generate theme.rasi
cat > "$THEME_OUTPUT" <<EOF
* {
    main-bg:            $(add_alpha "$mSurface" "E6");
    main-fg:            $(add_alpha "$mOnSurface" "FF");
    main-br:            $(add_alpha "$mTertiary" "E6");
    main-ex:            $(add_alpha "$mOnSurfaceVariant" "E6");
    select-bg:          $(add_alpha "$mPrimary" "80");
    select-fg:          $(add_alpha "$mOnPrimary" "FF");
    separatorcolor:     transparent;
    border-color:       $(add_alpha "$mOutline" "40");
}

EOF

echo "Rofi theme generated successfully at $THEME_OUTPUT"
