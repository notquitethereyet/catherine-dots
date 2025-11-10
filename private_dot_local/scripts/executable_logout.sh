#!/usr/bin/env sh

# # Directory to store the background image
# cache_dir="${HOME}/.cache"
# bg_image="${cache_dir}/wlogout.bg"

# # Ensure the cache directory exists
# mkdir -p "${cache_dir}"

# # Take screenshot, scale down, blur, and scale back up for efficiency
# grimblast save output "${cache_dir}/wlogout_temp.png"
# magick convert "${cache_dir}/wlogout_temp.png" -resize 25% -blur 0x8 "${bg_image}"
# rm "${cache_dir}/wlogout_temp.png"

# Check if wlogout is already running, and kill it if so
if pgrep -x "wlogout" > /dev/null; then
    pkill -x "wlogout"
    exit 0
fi
wlogout
