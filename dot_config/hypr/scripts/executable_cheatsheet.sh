#!/usr/bin/env bash

HYPR_CONF="$HOME/.config/hypr/keybindings.conf"
CACHE_FILE="$HOME/.cache/.keybindings_cache"

# Function to trim whitespace
trim() {
    echo "$1" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
}

# Function to extract variables and their values
declare -A VARS
extract_variables() {
    while IFS= read -r line; do
        if [[ "$line" =~ ^[[:space:]]*\$([a-zA-Z_0-9]*)[[:space:]]*=[[:space:]]*(.*)[[:space:]]*$ ]]; then
            VAR_NAME=$(trim "${BASH_REMATCH[1]}")
            VAR_VALUE=$(trim "${BASH_REMATCH[2]}")
            VARS["$VAR_NAME"]="$VAR_VALUE"
        fi
    done < "$HYPR_CONF"
}

# Function to generate formatted bindings and save them to cache
generate_cache() {
    # Extract all lines containing key bindings
    mapfile -t BINDINGS < <(grep -E '^[[:space:]]*bind[em]?[[:space:]]*=' "$HYPR_CONF")

    # Initialize an array to hold formatted bindings
    FORMATTED_BINDINGS=()

    for BINDING in "${BINDINGS[@]}"; do
        BINDING=$(echo "$BINDING" | sed -e 's/^[[:space:]]*bind[em]*[[:space:]]*=[[:space:]]*//g' -e 's/[[:space:]]*,[[:space:]]*/,/g')

        # Replace all variables in the binding with their values
        for VAR_NAME in "${!VARS[@]}"; do
            BINDING=$(echo "$BINDING" | sed -e "s/\$$VAR_NAME/${VARS[$VAR_NAME]}/g")
        done

        IFS=',' read -r MOD KEY ACTION REST <<< "$BINDING"
        CMD=$(echo "$REST" | awk -F, '{for(i=1;i<=NF;i++) printf $i " ";}')
        FORMATTED_BINDINGS+=("<b>${MOD} + ${KEY}</b>  <i>${ACTION}</i> <span color='gray'>${CMD}</span>")
    done

    # Save formatted bindings to cache
    printf '%s\n' "${FORMATTED_BINDINGS[@]}" > "$CACHE_FILE"
    echo "Cache generated successfully at $CACHE_FILE."
}

# Function to display the cheatsheet
display_cheatsheet() {
    # Ensure cache exists
    if [[ ! -f "$CACHE_FILE" ]]; then
        echo "Cache not found. Generating cache first..."
        extract_variables
        generate_cache
    fi

    # Display bindings from cache in rofi and get the selected choice
    CHOICE=$(cat "$CACHE_FILE" | rofi -dmenu -i -markup-rows -p "Hyprland Keybinds:")

    echo $CHOICE

    # Extract action and cmd from the selected choice
    ACTION=$(echo "$CHOICE" | sed -n "s/.*<i>\(.*\)<\/i>.*/\1/p")
    CMD=$(echo "$CHOICE" | sed -n "s/.*<span color='gray'>\(.*\)<\/span>.*/\1/p")

    # Check if CMD is not empty
    if [ -z "$CMD" ]; then
        exit 1
    fi

    # Execute the command if it starts with exec, otherwise use hyprctl dispatch
    if [[ "$ACTION" == "exec" ]]; then
        eval "$CMD"
    else
        hyprctl dispatch "$ACTION $CMD"
    fi
}

# Main logic based on argument
case "$1" in
    generate)
        extract_variables
        generate_cache
        ;;
    display)
        display_cheatsheet
        ;;
    *)
        echo "Usage: $0 {generate|display}"
        exit 1
        ;;
esac