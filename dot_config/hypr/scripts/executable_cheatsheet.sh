#!/usr/bin/env bash

# -------------------------------------------------------------------
# Script: hypr_keybinds.sh
# Description: Fetches and displays Hyprland keybindings in a formatted cheatsheet.
# Author: Your Name
# -------------------------------------------------------------------

# -----------------------------
# Configuration and Constants
# -----------------------------

# Directory for configuration and keybindings
CONF_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
KEYCONF_FILE="$CONF_DIR/hypr/keybindings.conf"

# Check if the keybindings.conf file exists
if [[ ! -f "$KEYCONF_FILE" ]]; then
    echo "Error: Keybindings configuration file not found at $KEYCONF_FILE"
    exit 1
fi

# Default delimiter and icon for display
DELIMITER="${1:->}"  # Allows setting a custom delimiter as the first argument
ICON=""  # Icon to prefix each keybinding

# -----------------------------
# Function: Display Help
# -----------------------------

show_help() {
    echo "Usage: $(basename "$0") [delimiter]"
    echo ""
    echo "Options:"
    echo "  delimiter    Custom delimiter symbol (default: '>')"
    echo "  -h, --help   Show this help message and exit"
    echo ""
    echo "Example:"
    echo "  $(basename "$0") '=>'"
}

# Handle help arguments
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    show_help
    exit 0
fi

# -----------------------------
# Function: Extract and Display Keybindings
# -----------------------------

# Use awk to parse and process keybindings
output=$(awk -v icon="$ICON" -v delimiter="$DELIMITER" '
BEGIN {
    FS="#"
}

# Capture variable definitions
/^\$/ {
    # Example: $mainMod = SUPER
    match($1, /^\$(\w+)[[:space:]]*=[[:space:]]*(.*)$/, arr)
    if (arr[1] != "" && arr[2] != "") {
        var[arr[1]] = arr[2]
    }
    next
}

# Process bind lines (bind, bindl, bindel, binde, bindm, etc.)
/^bind[a-z]*/ {
    # Example: bind = $mainMod, RETURN, exec, $term # launch terminal (kitty)
    # Extract the part before the '#' for keybinding and the part after for description
    keybind_part = $1
    description = $2

    # Skip lines without a description
    if (description == "") {
        next
    }

    # Remove everything before and including '='
    sub(/^[^=]*=[[:space:]]*/, "", keybind_part)

    # Remove $mainMod and any adjacent '+' or spaces
    gsub(/\$mainMod[ +]*/, "", keybind_part)

    # Split the keybind_part by ',' into parts
    split(keybind_part, parts, ",")

    keybind = ""
    cmd_keywords = "^(exec|movewindow|changegroupactive|togglefloating|exit|switch|killactive|resizewindow|movefocus|toggle)$"

    for (i = 1; i <= length(parts); i++) {
        part = parts[i]
        # Trim leading/trailing whitespace
        gsub(/^[ \t]+|[ \t]+$/, "", part)

        # Skip empty parts
        if (part == "") {
            continue
        }

        # Replace variables with their actual values
        if (match(part, /^\$(\w+)$/, var_arr)) {
            var_name = var_arr[1]
            if (var_name in var) {
                part = var[var_name]
            }
        }

        # Check if the part is a command keyword
        if (tolower(part) ~ cmd_keywords) {
            break
        }

        # Append the part to keybind with " + " separator
        if (keybind == "") {
            keybind = part
        } else {
            keybind = keybind " + " part
        }
    }

    # Prepend the icon
    if (keybind != "") {
        formatted_keybind = icon " + " keybind
    } else {
        formatted_keybind = icon
    }

    # Trim any remaining spaces
    gsub(/^[ \t]+|[ \t]+$/, "", formatted_keybind)

    # Trim description
    gsub(/^[ \t]+|[ \t]+$/, "", description)

    # Print the formatted keybinding and description
    printf "%-40s > %s\n", formatted_keybind, description
}
' "$KEYCONF_FILE" | sort)

# Check if output is empty
if [[ -z "$output" ]]; then
    echo "No keybindings found or failed to parse."
    exit 1
fi

# -----------------------------
# Function: Display Cheatsheet
# -----------------------------

display_cheatsheet() {
    echo "Keybinding                               $DELIMITER Description"
    echo "--------------------------------------------------------------------"
    echo "$output"
}

# -----------------------------
# Main Execution
# -----------------------------

# Check if rofi is installed
if command -v rofi >/dev/null 2>&1; then
    # Display using rofi
    formatted_output=$(display_cheatsheet)
    echo "$formatted_output" | rofi -dmenu -i -p "Hyprland Keybinds"
else
    # Else, display in terminal
    display_cheatsheet
    echo ""
    echo "Note: 'rofi' is not installed. Displayed in the terminal instead."
fi
