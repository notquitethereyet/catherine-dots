#!/bin/bash

# Try Spotify first
spotify_info=$(playerctl metadata --player spotify --format '{{title}}     {{artist}}' 2>/dev/null)

# Try Cider if Spotify isn't playing or not available
if [ -z "$spotify_info" ] || [ "$spotify_info" = " " ]; then
    cider_info=$(playerctl metadata --player cider --format '{{title}}     {{artist}}' 2>/dev/null)
    
    # Use Cider info if available
    if [ -n "$cider_info" ] && [ "$cider_info" != " " ]; then
        echo "$cider_info"
        exit 0
    fi
fi

# Default to Spotify info (even if empty)
echo "$spotify_info"


#!/bin/bash

song_info=$(playerctl metadata --player spotify --format '{{title}}     {{artist}}')

echo "$song_info" 