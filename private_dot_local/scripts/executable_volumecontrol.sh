#!/bin/bash

# Function to control output volume
control_output_volume() {
    case "$1" in
        i) # Increase volume
            pactl set-sink-volume @DEFAULT_SINK@ +5%
            notify-send "Volume" "Increased to $(pactl get-sink-volume @DEFAULT_SINK@ | awk '{print $5}')"
            ;;
        d) # Decrease volume
            pactl set-sink-volume @DEFAULT_SINK@ -5%
            notify-send "Volume" "Decreased to $(pactl get-sink-volume @DEFAULT_SINK@ | awk '{print $5}')"
            ;;
        m) # Toggle mute
            pactl set-sink-mute @DEFAULT_SINK@ toggle
            mute_status=$(pactl get-sink-mute @DEFAULT_SINK@ | awk '{print $2}')
            if [ "$mute_status" = "yes" ]; then
                notify-send "Volume" "Muted"
            else
                notify-send "Volume" "Unmuted"
            fi
            ;;
        *)
            echo "Invalid output volume option: $1"
            ;;
    esac
}

# Function to control microphone mute
control_input_volume() {
    case "$1" in
        m) # Toggle mute
            pactl set-source-mute @DEFAULT_SOURCE@ toggle
            mic_mute_status=$(pactl get-source-mute @DEFAULT_SOURCE@ | awk '{print $2}')
            if [ "$mic_mute_status" = "yes" ]; then
                notify-send "Microphone" "Muted"
            else
                notify-send "Microphone" "Unmuted"
            fi
            ;;
        *)
            echo "Invalid input volume option: $1"
            ;;
    esac
}

# Parse arguments for output (-o) or input (-i) control
while getopts "o:i:" opt; do
    case "$opt" in
        o) control_output_volume "$OPTARG" ;;
        i) control_input_volume "$OPTARG" ;;
        *) echo "Usage: $0 [-o <i|d|m>] [-i <m>]" ;;
    esac
done
