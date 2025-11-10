#!/usr/bin/env sh

# Define the system monitor tools to check in order of preference
pkgChk=("btop" "htop" "top")

# Fetch the preferred terminals from Hyprland keybindings configuration
term=$(grep -m 1 '^term=' "$HOME/.config/hypr/keybindings.conf" | cut -d '=' -f2 | xargs)
term2=$(grep -m 1 '^term2=' "$HOME/.config/hypr/keybindings.conf" | cut -d '=' -f2 | xargs)

# Determine which terminal to use, with a default fallback (e.g., alacritty or xterm)
terminal="${term:-$term2}"
terminal="${terminal:-kitty}"  # Change 'alacritty' to your preferred terminal as needed

# Ensure a terminal is available
if [ -z "$terminal" ]; then
    echo "No terminal found. Please check your keybindings.conf or specify a fallback."
    exit 1
fi

# Check each system monitor tool and open the first available one in the selected terminal
for sysMon in "${pkgChk[@]}"; do
    if command -v "$sysMon" > /dev/null 2>&1; then
        # If it's already running, kill it; otherwise, start it in the terminal
        pkill -x "$sysMon" || "$terminal" -e "$sysMon" &
        break
    fi
done
