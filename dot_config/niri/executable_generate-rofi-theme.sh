#!/usr/bin/env bash
# Manually generate rofi theme from Noctalia colors

COLORS_JSON="$HOME/.config/noctalia/colors.json"
TEMPLATE="$HOME/.config/noctalia/templates/rofi-theme.rasi"
OUTPUT="$HOME/.config/rofi/theme.rasi"

if [[ ! -f "$COLORS_JSON" ]]; then
    echo "Error: colors.json not found at $COLORS_JSON"
    exit 1
fi

if [[ ! -f "$TEMPLATE" ]]; then
    echo "Error: Template not found at $TEMPLATE"
    exit 1
fi

# Extract colors from colors.json
mSurface=$(jq -r '.mSurface' "$COLORS_JSON")
mOnSurface=$(jq -r '.mOnSurface' "$COLORS_JSON")
mPrimary=$(jq -r '.mPrimary' "$COLORS_JSON")
mOnPrimary=$(jq -r '.mOnPrimary' "$COLORS_JSON")
mSecondary=$(jq -r '.mSecondary' "$COLORS_JSON")
mOutline=$(jq -r '.mOutline' "$COLORS_JSON")

# Process template with sed replacements
sed -e "s|{{colors.surface.default.hex}}|${mSurface}|g" \
    -e "s|{{colors.on_surface.default.hex}}|${mOnSurface}|g" \
    -e "s|{{colors.primary.default.hex}}|${mPrimary}|g" \
    -e "s|{{colors.on_primary.default.hex}}|${mOnPrimary}|g" \
    -e "s|{{colors.secondary.default.hex}}|${mSecondary}|g" \
    -e "s|{{colors.outline.default.hex}}|${mOutline}|g" \
    "$TEMPLATE" > "$OUTPUT"

echo "Generated theme.rasi at $OUTPUT"

