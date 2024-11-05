#!/usr/bin/env sh

# Check if wlogout is already running, and kill it if so
if pgrep -x "wlogout" > /dev/null; then
    pkill -x "wlogout"
    exit 0
fi
wlogout