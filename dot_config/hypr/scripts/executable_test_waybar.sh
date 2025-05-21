#!/bin/bash
killall waybar
WAYLAND_DEBUG=1 waybar 2> ~/waybar_debug.log