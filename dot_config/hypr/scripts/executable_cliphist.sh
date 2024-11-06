#!/usr/bin/env sh

# Configuration
rofi_config="${HOME}/.config/rofi/config.rasi"
favorites_file="${HOME}/.cliphist_favorites"
rofi_font="JetBrainsMono Nerd Font 10"

# Helper function to display rofi with a theme
rofi_menu() {
    rofi -dmenu -theme-str "configuration {font: \"${rofi_font}\";}" -config "${rofi_config}"
}

# Show clipboard history if "c" argument is passed
if [ "$1" = "c" ]; then
    selected_item=$(cliphist list | rofi_menu)
    if [ -n "$selected_item" ]; then
        echo "$selected_item" | cliphist decode | wl-copy
        notify-send "Copied to clipboard."
    fi
    exit 0
fi

# Show main clipboard manager menu if no "c" argument is passed
main_action=$(echo -e "History\nDelete\nView Favorites\nManage Favorites\nClear History" | rofi_menu)

case "${main_action}" in
    "History")
        selected_item=$(cliphist list | rofi_menu)
        if [ -n "$selected_item" ]; then
            echo "$selected_item" | cliphist decode | wl-copy
            notify-send "Copied to clipboard."
        fi
        ;;
    "Delete")
        selected_item=$(cliphist list | rofi_menu)
        if [ -n "$selected_item" ]; then
            echo "$selected_item" | cliphist delete
            notify-send "Deleted."
        fi
        ;;
    "View Favorites")
        if [ -f "$favorites_file" ] && [ -s "$favorites_file" ]; then
            mapfile -t favorites < "$favorites_file"
            decoded_lines=()
            for favorite in "${favorites[@]}"; do
                decoded_lines+=("$(echo "$favorite" | base64 --decode | tr '\n' ' ')")
            done
            selected_favorite=$(printf "%s\n" "${decoded_lines[@]}" | rofi_menu)
            if [ -n "$selected_favorite" ]; then
                index=$(printf "%s\n" "${decoded_lines[@]}" | grep -nxF "$selected_favorite" | cut -d: -f1)
                if [ -n "$index" ]; then
                    echo "${favorites[$((index - 1))]}" | base64 --decode | wl-copy
                    notify-send "Copied to clipboard."
                fi
            fi
        else
            notify-send "No favorites."
        fi
        ;;
    "Manage Favorites")
        manage_action=$(echo -e "Add to Favorites\nDelete from Favorites\nClear All Favorites" | rofi_menu)
        case "${manage_action}" in
            "Add to Favorites")
                item=$(cliphist list | rofi_menu)
                if [ -n "$item" ]; then
                    encoded_item=$(echo "$item" | cliphist decode | base64 -w 0)
                    if ! grep -Fxq "$encoded_item" "$favorites_file"; then
                        echo "$encoded_item" >> "$favorites_file"
                        notify-send "Added to favorites."
                    else
                        notify-send "Item already in favorites."
                    fi
                fi
                ;;
            "Delete from Favorites")
                if [ -f "$favorites_file" ] && [ -s "$favorites_file" ]; then
                    mapfile -t favorites < "$favorites_file"
                    decoded_lines=()
                    for favorite in "${favorites[@]}"; do
                        decoded_lines+=("$(echo "$favorite" | base64 --decode | tr '\n' ' ')")
                    done
                    selected_favorite=$(printf "%s\n" "${decoded_lines[@]}" | rofi_menu)
                    if [ -n "$selected_favorite" ]; then
                        index=$(printf "%s\n" "${decoded_lines[@]}" | grep -nxF "$selected_favorite" | cut -d: -f1)
                        [ "$index" ] && sed -i "${index}d" "$favorites_file" && notify-send "Removed from favorites."
                    fi
                else
                    notify-send "No favorites to delete."
                fi
                ;;
            "Clear All Favorites")
                if [ -f "$favorites_file" ] && [ -s "$favorites_file" ]; then
                    confirm=$(echo -e "Yes\nNo" | rofi_menu)
                    [ "$confirm" = "Yes" ] && > "$favorites_file" && notify-send "Favorites cleared."
                else
                    notify-send "No favorites to clear."
                fi
                ;;
            *)
                exit 1
                ;;
        esac
        ;;
    "Clear History")
        confirm=$(echo -e "Yes\nNo" | rofi_menu)
        [ "$confirm" = "Yes" ] && cliphist wipe && notify-send "Clipboard history cleared."
        ;;
    *)
        exit 1
        ;;
esac
