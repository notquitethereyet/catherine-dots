#!/usr/bin/env sh

# Switch to the next keyboard layout
hyprctl switchxkblayout all next

# Get the active layout for the main keyboard
layMain=$(hyprctl -j devices | jq '.keyboards' | jq '.[] | select(.main == true)' | awk -F '"' '{if ($2=="active_keymap") print $4}')

# Display notification with the active layout
notify-send -a "t1" -r 91190 -t 800 -i "" "${layMain}"